module.exports = (grunt) ->
  web3 = require('web3')
  readYaml = require('read-yaml');

  grunt.registerTask "deploy_contracts", "deploy code", (env)  =>
    blockchainConfig = readYaml.sync("config/blockchain.yml")
    rpcHost   = blockchainConfig[env || "development"].rpc_host
    rpcPort   = blockchainConfig[env || "development"].rpc_port

    try
      web3.setProvider(new web3.providers.HttpProvider("http://#{rpcHost}:#{rpcPort}"))
      primaryAddress = web3.eth.coinbase
      web3.eth.defaultAccount = primaryAddress
    catch e
      grunt.log.writeln("==== can't connect to #{rpcHost}:#{rpcPort} check if an ethereum node is running")
      exit

    grunt.log.writeln("address is : #{primaryAddress}")

    result  = "web3.setProvider(new web3.providers.HttpProvider('http://#{rpcHost}:#{rpcPort}'));"
    result += "web3.eth.defaultAccount = web3.eth.accounts[0];"

    contractFiles = grunt.file.expand(grunt.config.get("deploy.contracts"))
    for contractFile in contractFiles
      source = grunt.file.read(contractFile)

      grunt.log.writeln("deploying #{contractFile}")
      contract = web3.eth.compile.solidity(source)
      contractAddress = web3.eth.sendTransaction({from: primaryAddress, data: contract.code})
      grunt.log.writeln("deployed at #{contractAddress}")

      abi = JSON.stringify(contract.info.abiDefinition)
      className = source.match(/contract (\w+)(?=\s[is|{])/g)[0].replace("contract ","")

      result += "var #{className}Abi = #{abi};"
      result += "var #{className}Contract = web3.eth.contract(#{className}Abi);"
      result += "var #{className} = new #{className}Contract('#{contractAddress}');";

    destFile = grunt.config.get("deploy.dest")
    grunt.file.write(destFile, result)

