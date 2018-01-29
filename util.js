const streamToPromise = require('stream-to-promise')
const { log, error } = console
const sshExec = require('ssh-exec')

module.exports = {
  remoteExec: async function(clientDC, serverDC, cmd, host, decoder, extractor) {
      log(`exec (${host}: ${cmd}`)

      const sshStream = sshExec(cmd, host)

      const startTS = new Date().toISOString()
      log(`starting: ${startTS}`)
      const sshResult = streamToPromise(sshStream)
        .then(buf => {
          return ((cDC, sDC, sTS) => {
            const decoded = decoder(buf)
            const extracted = extractor(decoded)
            const eTS =  new Date().toISOString()
            log(`ending: ${eTS}`)

            return {
              client: cDC,
              server: sDC,
              ...extracted,
            }
          })(clientDC, serverDC, startTS) // bind them vars in that there closure
        })
        // .catch(err => {
        //   error(`error while awaiting [${cmd}] (${host}): ${err.name} (${err.lineNumber}): ${err.message}`)
        //   exit(1)
        // })

      log(`awaiting ${cmd}`);
      return await sshResult
  }
}