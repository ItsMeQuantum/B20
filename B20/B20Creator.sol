// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IB20Factory} from "./IB20Factory.sol";
import {B20FactoryLib} from "./B20FactoryLib.sol";
import {B20Constants} from "./B20Constants.sol";
import {StdPrecompiles} from "./StdPrecompiles.sol";

contract B20Creator {

    address public lastCreatedToken;

    event TokenCreated(
        address indexed token,
        string name,
        string symbol,
        address indexed admin
    );

    function createToken(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 maxSupply,
        bytes32 salt
    ) external returns (address token) {

        // 1. Encode the B20 Asset creation parameters
        bytes memory params =
            B20FactoryLib.encodeAssetCreateParams(
                name,
                symbol,
                msg.sender,
                decimals
            );

        // 2. Create initialization calls
        bytes[] memory initCalls = new bytes[](2);

        // Give the caller permission to mint
        initCalls[0] =
            B20FactoryLib.encodeGrantRole(
                B20Constants.MINT_ROLE,
                msg.sender
            );

        // Set the maximum supply
        initCalls[1] =
            B20FactoryLib.encodeUpdateSupplyCap(
                maxSupply
            );

        // 3. Create the B20 token
        token =
            StdPrecompiles.B20_FACTORY.createB20(
                IB20Factory.B20Variant.ASSET,
                salt,
                params,
                initCalls
            );

        // 4. Remember the token address
        lastCreatedToken = token;

        emit TokenCreated(
            token,
            name,
            symbol,
            msg.sender
        );
    }
}