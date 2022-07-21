// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {
    IERC20,
    IERC721,
    IERC1155
} from "src/interfaces/AbridgedTokenInterfaces.sol";

import {
    TokenTransferrerErrors
} from "src/interfaces/TokenTransferrerErrors.sol";

// seaport, mod erc20.transferFrom -> erc20transfer
contract TokenTransferrer is TokenTransferrerErrors {
    /**
     * @dev Internal function to transfer ERC20 tokens from a given originator
     *      to a given recipient. Sufficient approvals must be set on the
     *      contract performing the transfer.
     *
     * @param token      The ERC20 token to transfer.
     * @param to         The recipient of the transfer.
     * @param amount     The amount to transfer.
     */
    function _performERC20Transfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (token.code.length == 0) {
            revert NoContract(token);
        }

        (bool ok, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transfer.selector,
                to,
                amount
            )
        );

        // NOTE: revert reasons are not "bubbled up" at the moment
        if (!ok) {
            revert TokenTransferGenericFailure(token, address(this), to, 0, amount);
        }

        if (data.length != 0 && data.length >= 32) {
            if (!abi.decode(data, (bool))) {
                revert BadReturnValueFromERC20OnTransfer(
                    token,
                    address(this),
                    to,
                    amount
                );
            }
        }
    }

    /**
     * @dev Internal function to transfer an ERC721 token from a given
     *      originator to a given recipient. Sufficient approvals must be set on
     *      the contract performing the transfer.
     *
     * @param token      The ERC721 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param id The tokenId to transfer.
     */
    function _performERC721Transfer(
        address token,
        address from,
        address to,
        uint256 id
    ) internal {
        if (token.code.length == 0) {
            revert NoContract(token);
        }

        IERC721(token).transferFrom(from, to, id);
    }

    /**
     * @dev Internal function to transfer ERC1155 tokens from a given
     *      originator to a given recipient. Sufficient approvals must be set on
     *      the contract performing the transfer and contract recipients must
     *      implement onReceived to indicate that they are willing to accept the
     *      transfer.
     *
     * @param token      The ERC1155 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param id The id to transfer.
     * @param amount     The amount to transfer.
     */
    function _performERC1155Transfer(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        if (token.code.length == 0) {
            revert NoContract(token);
        }

        IERC1155(token).safeTransferFrom(
            from,
            to,
            id,
            amount,
            ""
        );
    }
}