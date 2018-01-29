const { parse } = JSON
const { log, error } = console

module.exports = {
  iperf3: function(buffer) {
    const decoded = buffer.toString('utf-8')
    log(`decoded iperf output: ${decoded}`);
    const parsed = parse(decoded)
    log(`parsed iperf output: ${parsed}`);
    return parsed
  },
  ping: function(buffer) {
    const decoded = buffer.toString('utf-8')
    log(`decoded iperf output: ${decoded}`);    
    return decoded
  }
}