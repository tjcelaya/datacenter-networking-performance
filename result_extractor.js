const assert = require('assert')
const { stringify } = JSON
const { best } = require('unitz')
const { log, error } = console
const { iperf3JsonExtractor } = require("./result_extractor")

module.exports = {
  iperf3JsonExtractor: function (output) {
    try {

      log("streams: " + stringify(output['start']['test_start']))

      assert.ok(undefined !== output['start'])
      assert.ok(undefined !== output['start']['test_start'])
      assert.ok(undefined !== output['start']['test_start']['num_streams'])
      assert.ok(undefined !== output['start']['test_start']['duration'])
      assert.ok(undefined !== output['end'])
      assert.ok(undefined !== output['end']['sum_sent'])
      assert.ok(undefined !== output['end']['sum_sent']['bits_per_second'])
      assert.ok(undefined !== output['end']['sum_received'])
      assert.ok(undefined !== output['end']['sum_received']['bits_per_second'])
    } catch (e) {
      throw new Error(`result validation error: ${e.name}: ${e.message}`)
    }

    const threads = output['start']['test_start']['num_streams']
    const duration = output['start']['test_start']['duration']
    const bits_per_second_sent = output['end']['sum_sent']['bits_per_second']
    const bits_per_second_recv = output['end']['sum_received']['bits_per_second']

    return {
      threads,
      duration,
      bandwidth_sent: `${best(`${bits_per_second_sent} bits`).convert('gbit')} Gbps`,
      bandwidth_recv: `${best(`${bits_per_second_recv} bits`).convert('gbit')} Gbps`,
    }
  }
}