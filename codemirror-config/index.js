const http = require('http')
const url = require('url')
const process = require('process')

const port = 3000

process.title = process.argv[2]

const isValidJSONString = (str) => {
  try {
      JSON.parse(str)
  } catch (e) {
      return false
  }
  return true
}

const requestHandler = (request, response) => {
  let query = url.parse(request.url, true).query
  // console.log(`\n\n\n${query.jsonToValidate}\n\n\n`)
  response.end(`${isValidJSONString(query.jsonToValidate)}`)
}

const server = http.createServer(requestHandler)

server.listen(port, (err) => {
  if (err) {
    return console.log('something bad happened', err)
  }
  console.log(`server is listening on port ${port}. process title ${process.title}`)
})
