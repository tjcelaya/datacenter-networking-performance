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
const { remoteExec } = require('./util')
const joinByKeys = require('join-by-keys')
const { iperf3Json: iperf3JsonExtractor, ping: pingExtractor } = require('./extractor')
const { iperf3: iperf3Decoder, ping: pingDecoder } = require('./decoder')
const { writeFileSync } = require('fs')

assert.ok((typeof iperf3JsonExtractor) == 'function')
assert.ok((typeof pingExtractor) == 'function')
assert.ok((typeof iperf3Decoder) == 'function')
assert.ok((typeof pingDecoder) == 'function')


const { table } = require('table')

const ARGV = require('minimist')(process.argv.slice(2), {
  boolean: ['help', 'private', 'skip_file'],
  alias: {
    h: 'help',
  },
  default: {
    help: false,
    private: false,
    skip_file: false,
    iperf_seconds: 10,
    iperf_threads: 8,
    pings: 10,
    hosts: '',
    user: 'root',
  }
})

const ARG_HELP = ARGV['help']
const ARG_USE_PUBLIC_SERVER_ADDRESS = !ARGV['private']
const ARG_PING_COUNT = ARGV['pings']
const ARG_IPERF_THREADS = ARGV['iperf_threads']
const ARG_IPERF_SECONDS = ARGV['iperf_seconds']
const ARG_HOST_FILTER = ARGV['hosts']
const ARG_USER = ARGV['user']
const ARG_SKIP_FILE = ARGV['skip_file']

if (ARG_HELP) {
  log(
`
Usage: main.js <options>
  --help            Show this help.
  --private         Use private server addresses.
  --skip_file       Skip dumping results to <TIMESTAMP>.dnp
  --iperf_seconds   Seconds to run iperf3 test.
  --iperf_threads   Threads to use in iperf3 test.
  --pings           Number of pings to send.
  --hosts           Regex for matching hosts in Terraform output.
  --user            Username for SSH access.

Prints results in a table. Dumps results to <TIMESTAMP>.dnp by default.
`)
  exit(0)
}

log(`ARG_USE_PUBLIC_SERVER_ADDRESS: ${ARG_USE_PUBLIC_SERVER_ADDRESS}`)
log(`ARG_PING_COUNT: ${ARG_PING_COUNT}`)
log(`ARG_IPERF_THREADS: ${ARG_IPERF_THREADS}`)
log(`ARG_IPERF_SECONDS: ${ARG_IPERF_SECONDS}`)
log(`ARG_HOST_FILTER: ${ARG_HOST_FILTER}`)

const test_start_timestamp = new Date().toISOString()
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

      const start_at = new Date().toISOString()

      const iperfSSH = remoteExec(
        clientDC,
        serverDC,
        iperfCmd,
        `${ARG_USER}@${clients[clientDC]}`,
        iperf3Decoder,
        iperf3JsonExtractor)

      log('awaiting iperf output');
      const perfResult = await iperfSSH

      log('stashing iperf output');
      results.push(perfResult)

      const pingSSH = remoteExec(
        clientDC,
        serverDC,
        `ping -c ${ARG_PING_COUNT} ${serverIP} 2>&1`,
        `${ARG_USER}@${clients[clientDC]}`,
        pingDecoder,
        pingExtractor)

      log('awaiting ping output');
      const pingResult = await pingSSH
      log('stashing ping output');


      results.push({
        start_at,
        end_at: new Date().toISOString(),
        ...joinByKeys(results, ['client', 'server'])
      })

      // instance type metadata query


      // aws: curl http://169.254.169.254/latest/meta-data/instance-type


      log(`${clientDC} -> ${serverDC} completed`)
      log(`${clients[clientDC]} finished`)
    }
  }


  log(`waiting...`)
  // TODO: parallelize more intelligently
  // const finalResults = await Promise.all(execs)

  // dump to file
  if (!ARG_SKIP_FILE) {
    writeFileSync(`${test_start_timestamp}.dnp`, stringify(results))
  }

  log(table([keys(results[0]), ...results.map(Object.values)]))
})()
