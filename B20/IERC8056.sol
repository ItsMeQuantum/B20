// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

interface IScaledUIAmount {
    event UIMultiplierUpdated(
        uint256 oldMultiplier,
        uint256 newMultiplier,
        uint256 effectiveAtTimestamp
    );

    function uiMultiplier()
        external
        view
        returns (uint256);
}

interface IScaledUIAmountNewUIMultiplier {
    function newUIMultiplier()
        external
        view
        returns (uint256);

    function effectiveAt()
        external
        view
        returns (uint256);
}

interface IScaledUIAmountBalances {
    function balanceOfUI(
        address account
    ) external view returns (uint256);

    function totalSupplyUI()
        external
        view
        returns (uint256);
}

interface IScaledUIAmountConversion {
    function toUIAmount(
        uint256 rawAmount
    ) external view returns (uint256);

    function fromUIAmount(
        uint256 uiAmount
    ) external view returns (uint256);
}