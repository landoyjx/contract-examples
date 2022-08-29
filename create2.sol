pragma solidity 0.5.16;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Wallet {
    constructor(address token, address to) public {
        // send all tokens from this contract to hotwallet
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "!needed");
        require(IERC20(token).transfer(
            to,
            balance
        ), "collect failed");
        // selfdestruct to receive gas refund and reset nonce to 0
        selfdestruct(address(0x0));
    }
}

contract Fabric {

    function getBytecode(address token, address to) public pure returns (bytes memory) {
        bytes memory bytecode = type(Wallet).creationCode;
        return abi.encodePacked(bytecode, uint256(token), uint256(to));
    }

    function getAddress(address token, address to, uint256 salt) public view returns (address output) {
        bytes memory bytecode = getBytecode(token, to);
        output = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this), // creator
                abi.encodePacked(salt), // salt
                keccak256(bytecode) // init code hash
            ))));
    }

    function collect(address token, address to, uint256 salt) external returns (address wallet) {
        bytes memory bytecode = getBytecode(token, to);
        assembly {
            wallet := create2(
                0, // 0 wei
                add(bytecode, 32), // the bytecode itself starts at the second slot. The first slot contains array length
                mload(bytecode), // size of init_code
                salt // salt from function arguments
            )
        }
    }
}
