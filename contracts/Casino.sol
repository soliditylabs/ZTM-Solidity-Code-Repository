// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Casino {
    mapping(address => uint256) public gameWeiValues;
    mapping(address => uint256) public blockHashesToBeUsed;

    function playGame() external payable {
        if (blockHashesToBeUsed[msg.sender] == 0) {
            blockHashesToBeUsed[msg.sender] = block.number + 2;
            gameWeiValues[msg.sender] = msg.value;
            return;
        }

        require(
            msg.value == 0,
            "Lottery: Finish current game before starting new one"
        );
        require(
            blockhash(blockHashesToBeUsed[msg.sender]) != 0,
            "Lottery: Block not mined yet"
        );

        uint256 randomNumber = uint256(
            blockhash(blockHashesToBeUsed[msg.sender])
        );

        if (randomNumber != 0 && randomNumber % 2 == 0) {
            uint256 winningAmount = gameWeiValues[msg.sender] * 2;
            (bool success, ) = msg.sender.call{value: winningAmount}("");
            require(success, "Lottery: Winning payout failed");
        }

        blockHashesToBeUsed[msg.sender] = 0;
        gameWeiValues[msg.sender] = 0;
    }
}
