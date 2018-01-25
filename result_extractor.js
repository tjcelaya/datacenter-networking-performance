const assert = require('assert')
const { stringify } = JSON
const { best } = require('unitz')
const { log, error } = console

module.exports = {
  iperf3JsonExtractor: function (output) {
    try {
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
      duration: `${duration}s`,
      bandwidth_sent: `${best(`${bits_per_second_sent} bits`).convert('gbit')} Gbps`,
      bandwidth_recv: `${best(`${bits_per_second_recv} bits`).convert('gbit')} Gbps`,
    }
  },

  pingExtractor: function (output) {
    const byLine = output.trimRight().split(/\n/g)
    const timingSummary = byLine.pop()

    const [ ping_min, ping_avg, ping_max, ping_mdev, ping_units ] =
      timingSummary.replace('rtt min\/avg\/max\/mdev = ','').split(/\/| /)

    const packetSummary = byLine.pop()

    const [ ping_packets_tx, ping_packets_rx, ping_packet_loss_percent ] =
      packetSummary.replace(/[A-z, ]+/g, ',').split(',').slice(0, -1)

    return {
      ping_min: `${ping_min} ${ping_units}`,
      ping_avg: `${ping_avg} ${ping_units}`,
      ping_max: `${ping_max} ${ping_units}`,
      ping_mdev: `${ping_mdev} ${ping_units}`,
      ping_packet_loss_percent,
    }
  }
}
