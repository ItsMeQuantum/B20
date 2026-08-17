// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IB20Factory} from "./IB20Factory.sol";

library StdPrecompiles {
    address internal constant B20_FACTORY_ADDRESS =
        0xB20f000000000000000000000000000000000000;

    IB20Factory internal constant B20_FACTORY =
        IB20Factory(B20_FACTORY_ADDRESS);
}