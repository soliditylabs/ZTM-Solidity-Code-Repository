// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "./ERC20.sol";
import {DepositorCoin} from "./DepositorCoin.sol";
import {Oracle} from "./Oracle.sol";
import {FixedPoint, fromFraction, mulFixedPoint, divFixedPoint} from "./FixedPoint.sol";

contract Stablecoin is ERC20 {
    DepositorCoin public depositorCoin;
    Oracle public oracle;
    uint256 public feeRatePercentage;
    uint256 public initialCollateralRatioPercentage;
    uint256 public depositorCoinLockTime;

    error InitialCollateralRatioError(
        string message,
        uint256 minimumDepositAmount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        Oracle _oracle,
        uint256 _feeRatePercentage,
        uint256 _initialCollateralRatioPercentage,
        uint256 _depositorCoinLockTime
    ) ERC20(_name, _symbol, 18) {
        oracle = _oracle;
        feeRatePercentage = _feeRatePercentage;
        initialCollateralRatioPercentage = _initialCollateralRatioPercentage;
        depositorCoinLockTime = _depositorCoinLockTime;
    }

    function mint() external payable {
        uint256 fee = _getFee(msg.value);
        uint256 mintStablecoinAmount = (msg.value - fee) * oracle.getPrice();
        _mint(msg.sender, mintStablecoinAmount);
    }

    function burn(uint256 burnStablecoinAmount) external {
        _burn(msg.sender, burnStablecoinAmount);

        uint256 refundingEth = burnStablecoinAmount / oracle.getPrice();
        uint256 fee = _getFee(refundingEth);

        (bool success, ) = msg.sender.call{value: (refundingEth - fee)}("");
        require(success, "STC: Burn refund transaction failed");
    }

    function _getFee(uint256 ethAmount) private view returns (uint256) {
        return (ethAmount * feeRatePercentage) / 100;
    }

    function depositCollateralBuffer() external payable {
        int256 deficitOrSurplusInUsd = _getDeficitOrSurplusInContractInUsd();

        if (deficitOrSurplusInUsd <= 0) {
            uint256 deficitInUsd = uint256(deficitOrSurplusInUsd * -1);
            uint256 deficitInEth = deficitInUsd / oracle.getPrice();

            uint256 addedSurplusEth = msg.value - deficitInEth;

            uint256 requiredInitialSurplusInUsd = (initialCollateralRatioPercentage *
                    totalSupply) / 100;
            uint256 requiredInitialSurplusInEth = requiredInitialSurplusInUsd /
                oracle.getPrice();

            if (addedSurplusEth < requiredInitialSurplusInEth) {
                uint256 minimumDeposit = deficitInEth +
                    requiredInitialSurplusInEth;

                revert InitialCollateralRatioError(
                    "STC: Initial collateral ratio not met, minimum is",
                    minimumDeposit
                );
            }

            uint256 initialDepositorSupply = addedSurplusEth *
                oracle.getPrice();
            depositorCoin = new DepositorCoin(
                "Depositor Coin",
                "DPC",
                depositorCoinLockTime,
                msg.sender,
                initialDepositorSupply
            );
            // new surplus: (msg.value - deficitInEth) * oracle.getPrice();

            return;
        }

        uint256 surplusInUsd = uint256(deficitOrSurplusInUsd);

        // usdInDpcPrice = 250 / 500 = 0.5e18
        FixedPoint usdInDpcPrice = fromFraction(
            depositorCoin.totalSupply(),
            surplusInUsd
        );

        // 0.5e18 * 1000 * 0.5e18 = 250e36
        uint256 mintDepositorCoinAmount = mulFixedPoint(
            msg.value * oracle.getPrice(),
            usdInDpcPrice
        );
        depositorCoin.mint(msg.sender, mintDepositorCoinAmount);
    }

    function withdrawCollateralBuffer(
        uint256 burnDepositorCoinAmount
    ) external {
        int256 deficitOrSurplusInUsd = _getDeficitOrSurplusInContractInUsd();
        require(
            deficitOrSurplusInUsd > 0,
            "STC: No depositor funds to withdraw"
        );

        uint256 surplusInUsd = uint256(deficitOrSurplusInUsd);
        depositorCoin.burn(msg.sender, burnDepositorCoinAmount);

        // usdInDpcPrice = 250 / 500 = 0.5
        FixedPoint usdInDpcPrice = fromFraction(
            depositorCoin.totalSupply(),
            surplusInUsd
        );

        // 125 / 0.5 = 250
        uint256 refundingUsd = divFixedPoint(
            burnDepositorCoinAmount,
            usdInDpcPrice
        );

        // 250 / 1000 = 0.25 ETH
        uint256 refundingEth = refundingUsd / oracle.getPrice();

        (bool success, ) = msg.sender.call{value: refundingEth}("");
        require(success, "STC: Withdraw collateral buffer transaction failed");
    }

    function _getDeficitOrSurplusInContractInUsd()
        private
        view
        returns (int256)
    {
        uint256 ethContractBalanceInUsd = (address(this).balance - msg.value) *
            oracle.getPrice();

        uint256 totalStableCoinBalanceInUsd = totalSupply;

        int256 surplusOrDeficit = int256(ethContractBalanceInUsd) -
            int256(totalStableCoinBalanceInUsd);
        return surplusOrDeficit;
    }
}
