#!/usr/bin/env node
const assert = require('assert')
const sshExec = require('ssh-exec')
const streamToPromise = require('stream-to-promise')
const { parse, stringify } = JSON
const { entries } = Object
const { log, error } = console
const { exit } = process
const { execSync } = require('child_process')
const { isPrivate } = require('ip')

const tf_out = execSync('terraform output -json', { encoding: 'utf8' })
const inv = parse(tf_out)

log(`inventory:\n ${tf_out}`)

// map of { dcX: private server IP }
const servers = {}
// map of { dcX: public client IP }
const clients = {}

// nested map of { clientDC: { serverDC: aggregate Gbit/s } }
const results = {}

for (const node in inv) {

  const [ dc, role ] = node.split('_')
  const ips = inv[node]['value']

  log(`dc ${dc} role ${role} ips: ${stringify(ips)}`)
  
  assert.ok(['server', 'client'].includes(role), 'unexpected role')

  assert.ok(ips.length === 2, 'unexpected number of addresses')
  assert.ok(!isPrivate(ips[0]), 'first address was not public')
  assert.ok(isPrivate(ips[1]), 'second address was not private')

  if (role === 'client') {
    clients[dc] = ips[0]
  } else {
    servers[dc] = ips[1]
  }
}

for (const clientDC in clients) {
  for (const serverDC in servers) {
    results[clientDC] = { [serverDC]: null }
  }
}

log(`test plan: ${stringify(results)}`);


(async function() {

  const collected = []

  for (const clientDC in results) {
    for (const serverDC in results[clientDC]) {

      const clientIP = clients[clientDC]
      const serverIP = servers[serverDC]

      log(`${clientDC} (${clientIP}) -> ${serverDC} (${serverIP}) starting`)

      const sshStream = sshExec('/usr/local/bin/terse_iperf_client.sh 2>&1', `root@${clients[clientDC]}`)

      const sshResult = streamToPromise(sshStream)
        .then(buf => {
          return ((cDC, sDC) => {
            return {
              client: cDC,
              server: sDC,
              result: buf.toString('utf-8'),
            }
          })(clientDC, serverDC)
        })
        .catch(err => {
          error(`error while awaiting result: ${err.name}: ${err.message}`)
          exit(1)
        })

      const perfResult = await sshResult

      collected.push(perfResult)

      log(`${clientDC} -> ${serverDC} completed`)
      log(`${clients[clientDC]} finished`)
    }
  }

  log(`waiting...`)

  // const finalResults = await Promise.all(execs)

  log(`collected: ${stringify(collected)}`)

  for (const perf of collected) {
    assert.ok(perf['client'] !== undefined)
    assert.ok(perf['server'] !== undefined)
    assert.ok(perf['result'] !== undefined)

    const clientResult = perf['client']
    const serverResult = perf['server']
    const perfResult = perf['result']

    results[clientResult][serverResult] = perfResult
  }

  log(`results: ${stringify(results)}`)
})()