#!/usr/bin/env node
const assert = require('assert')
const sshExec = require('ssh-exec')
const streamToPromise = require('stream-to-promise')
const { parse, stringify } = JSON
const { keys } = Object
const { log, error } = console
const { exit } = process
const { execSync } = require('child_process')
const { isPrivate } = require('ip')
const { iperf3JsonExtractor, pingExtractor } = require('./result_extractor')
const joinByKeys = require('join-by-keys')

const { table } = require('table')

const ARGV = require('minimist')(process.argv.slice(2), {
  boolean: ['private'],
  default: {
    private: false,
    iperf_seconds: 10,
    iperf_threads: 8,
    pings: 10,
    hosts: '',
  }
})

const ARG_USE_PUBLIC_SERVER_ADDRESS = !ARGV['private']
const ARG_PING_COUNT = ARGV['pings']
const ARG_IPERF_THREADS = ARGV['iperf_threads']
const ARG_IPERF_SECONDS = ARGV['iperf_seconds']
const ARG_HOST_FILTER = ARGV['hosts']

log(`ARG_USE_PUBLIC_SERVER_ADDRESS: ${ARG_USE_PUBLIC_SERVER_ADDRESS}`)
log(`ARG_PING_COUNT: ${ARG_PING_COUNT}`)
log(`ARG_IPERF_THREADS: ${ARG_IPERF_THREADS}`)
log(`ARG_IPERF_SECONDS: ${ARG_IPERF_SECONDS}`)
log(`ARG_HOST_FILTER: ${ARG_HOST_FILTER}`)


const tf_out = execSync('terraform output -json', { encoding: 'utf8' })
const inv = parse(tf_out)

// map of { dcX: private server IP }
const servers = {}
// map of { dcX: public client IP }
const clients = {}

// array of records
const results = []

for (const node in inv) {
  const [ dc, role ] = node.split('_')

  if (ARG_HOST_FILTER !== '') {
    // a filter was given, skip if it doesn't match
    if (dc.match(ARG_HOST_FILTER) === null) {
      continue
    }
  }

  const ips = inv[node]['value']

  log(`dc ${dc} role ${role} ips: ${stringify(ips)}`)
  
  assert.ok(['server', 'client'].includes(role), 'unexpected role')

  assert.ok(ips.length === 2, 'unexpected number of addresses')
  assert.ok(!isPrivate(ips[0]), 'first address was not public')
  assert.ok(isPrivate(ips[1]), 'second address was not private')

  if (role === 'client') {
    clients[dc] = ips[0]
  } else {
    if (ARG_USE_PUBLIC_SERVER_ADDRESS) {
      servers[dc] = ips[0]
    } else {
      servers[dc] = ips[1]
    }
  }
}

log('servers:', servers);
log('clients:', clients);

(async function() {
  for (const clientDC of keys(clients)) {
    for (const serverDC of keys(servers)) {

      const clientIP = clients[clientDC]
      const serverIP = servers[serverDC]

      log(`${clientDC} (${clientIP}) -> ${serverDC} (${serverIP}) starting`)

      const iperfEnvs = `TIME_SECONDS=${ARG_IPERF_SECONDS} THREAD_COUNT=${ARG_IPERF_THREADS}`
      const iperfCmd = `${iperfEnvs} /usr/local/bin/terse_iperf_client.sh ${serverIP} 2>&1`

      const iperfSSHStream = sshExec(iperfCmd, `root@${clients[clientDC]}`)

      const iperfSSH = streamToPromise(iperfSSHStream)
        .then(buf => {
          return ((cDC, sDC) => {
            const decoded = buf.toString('utf-8')
            const parsed = parse(decoded)

            return {
              client: cDC,
              server: sDC,
              ...iperf3JsonExtractor(parsed),
            }
          })(clientDC, serverDC) // bind them vars in that there closure
        })
        .catch(err => {
          error(`error while awaiting result: ${err.name} (${err.lineNumber}): ${err.message}`)
          exit(1)
        })

      const perfResult = await iperfSSH
      results.push(perfResult)

      const pingSSHStream = sshExec(
        `ping -c ${ARG_PING_COUNT} ${serverIP} 2>&1`,
        `root@${clients[clientDC]}`)

      const pingSSH = streamToPromise(pingSSHStream)
        .then(buf => {
          return ((cDC, sDC) => {
            const decoded = buf.toString('utf-8')

            return {
              client: cDC,
              server: sDC,
              ...pingExtractor(decoded),
            }
          })(clientDC, serverDC) // bind them vars in that there closure
        })
        .catch(err => {
          error(`error while awaiting result: ${err.name} (${err.lineNumber}): ${err.message}`)
          exit(1)
        })

      const pingResult = await pingSSH

      results.push(pingResult)

      log(`${clientDC} -> ${serverDC} completed`)
      log(`${clients[clientDC]} finished`)
    }
  }

  log(`waiting...`)

  const joinedResults = joinByKeys(results, ['client', 'server'])

  // const finalResults = await Promise.all(execs)

  log(table([keys(joinedResults[0]), ...joinedResults.map(Object.values)]))
})()