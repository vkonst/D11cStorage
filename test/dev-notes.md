
## To give an idea of what/how to test ....

```typescript 
const [deployer, anybody] = await ethers.getSigners()
```
## TODO: zero padding needed
```typescript 
const getRandomByteStr = (length) => ethers.utils.randomBytes(length).reduce((a, b) => a+("0"+b.toString(16)).slice(-2), '0x')
```
## Simulate deployed deterministic-deployer-proxy on the hardhat (local) network
```typescript 
const d11cDeployerAddr = '0x4e59b44847b379578588920cA78FbF26c0B4956C'
const d11cDeployerCode = '0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3'
await network.provider.send('hardhat_setCode', [d11cDeployerAddr, d11cDeployerCode])
assert(await ethers.provider.getCode(d11cDeployerAddr) == content)
```

## Test deterministic-deployer-proxy to the local hardhat network
```typescript 
let content = getRandomByteStr(16*32) // 16 x 32-byte words
const dataPrefix = '0x0c3d72390ac0ce0233c551a3c5278f8625ba996f5985dc8d612a9fc55f1de15a600b5981380380925939f3'
let callData = dataPrefix + content.replace('0x', '')
let pointer =  await deployer.call({to: d11cDeployerAddr, data: callData})
const tx0 = await deployer.sendTransaction({to: d11cDeployerAddr, data: callData})
assert(await ethers.provider.getCode(pointer) == content)
await tx0.wait().then(rcp => rcp.gasUsed.toNumber()) // 164707
```

## Test D11cSSTORE2
```typescript 
const Tester = await ethers.getContractFactory('D11cSSTORE2Tester', deployer)
const tester = await Tester.deploy()

let content = getRandomByteStr(16*32)
assert(await tester.testGetInitCode(content) == '0x600b5981380380925939f300' + content.replace('0x', ''))

let resp = await deployer.call({to: tester.address, data: Tester.interface.encodeFunctionData('testWrite(bytes)', [content])})
const [pointer1] = ethers.utils.defaultAbiCoder.decode(['address'], resp)
let initCode = await tester.testGetInitCode(content)
let pointer2 = await tester.testGetDataAddress(initCode)
assert(pointer1 == pointer2)

const tx1 = await tester.testWrite(content)
const rcp1 = await tx1.wait()
rcp1.gasUsed.toNumber() // 172463

assert(await tester.testRead(pointer1) == content)
assert(await tester.testReadFromTo(pointer1, 0, 3) == content.substr(0, 8))
assert(await tester.testReadFromTo(pointer1, 3, (content.length-2)/2) ==  '0x' + content.substr(8,))

const tx2 = await deployer.sendTransaction({to: tester.address, value: 0, data: Tester.interface.encodeFunctionData('testRead(address)', [pointer])})
await tx2.wait().then(rcp => rcp.gasUsed.toNumber()) // 26195
```

## .. let's write/read some structured data
```typescript 

const Tester2 = await ethers.getContractFactory('D11cSSTORE2UintArrayTester', deployer)
const tester2 = await Tester2.deploy()

content = Array(127).fill(0).map( (_) => getRandomByteStr(32))
let encodedContent = ethers.utils.defaultAbiCoder.encode(['bytes32[]'], [content])

resp = await deployer.call({to: tester2.address, data: Tester2.interface.encodeFunctionData('writeAsUintArray(uint256[])', [content])})
const [pointer3] = ethers.utils.defaultAbiCoder.decode(['address'], resp)
const tx5 = await tester2.writeAsUintArray(content)
await tx5.wait().then(rcp => rcp.gasUsed.toNumber()) // 1001782

let loadedContent = await tester2.readAsUintArray(pointer3)
let isSame = loadedContent.reduce((acc, lc, i) => acc && (lc.toHexString() == content[i].toString(16)), loadedContent.length == content.length)
assert(isSame)

const tx6 = await deployer.sendTransaction({to: tester2.address, value: 0, data: Tester2.interface.encodeFunctionData('readAsUintArray(address)', [pointer3])})
await tx6.wait().then(rcp => rcp.gasUsed.toNumber()) // 46505
const _tx6 = await deployer.sendTransaction({to: tester2.address, value: 0, data: Tester2.interface.encodeFunctionData('altReadAsUintArray(address)', [pointer3])})
await _tx6.wait().then(rcp => rcp.gasUsed.toNumber()) // 46395
```

## Test CONSTRUCTOR_AND_HEADER of D11cRemovableWriter
```typescript 

const constructor2 = '0x323d55600e3d81380380923d39f3'
const deployedCodeHeader2 = '0x333d5403600c573d805533ff5b00'
data = getRandomByteStr(128)
deployedCode = ethers.utils.solidityPack(['bytes', 'bytes'], [deployedCodeHeader2, data])
initCode = ethers.utils.solidityPack(['bytes', 'bytes'], [constructor2, deployedCode])
salt = getRandomByteStr(32)
callData = ethers.utils.solidityPack(['bytes', 'bytes'], [salt, initCode])
const pointer4 =  await deployer.call({to: d11cDeployerAddr, data: callData})
const tx8 = await deployer.sendTransaction({to: d11cDeployerAddr, data: callData})
assert(ethers.utils.defaultAbiCoder.decode(['address'], await ethers.provider.getStorageAt(pointer4, 0))[0] == deployer.address)
assert(await ethers.provider.getCode(pointer4) == deployedCode)
(await tx8.wait()).gasUsed.toNumber() // 106705
const tx12 = await deployer.sendTransaction({to: tester.address, value: 0, data: Tester.interface.encodeFunctionData('testRead(address)', [pointer4])})
await tx12.wait().then(rcp => rcp.gasUsed.toNumber()) // 25945
assert(await tester.testRead(pointer4) == '0x' + deployedCode.replace('0x', '').substr(2))
const tx9 = await anybody.sendTransaction({to: pointer4})
assert(await ethers.provider.getCode(pointer4) == deployedCode)
const tx10 = await deployer.sendTransaction({to: pointer4})
assert(await ethers.provider.getCode(pointer4) == '0x')
(await tx10.wait()).gasUsed.toNumber() // 26227
```