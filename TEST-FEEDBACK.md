
SECOND PHASE OF TESTING
1. Wallet Name Change doesn't work as intended. Basically when you change the name of one wallet, it changes it accurately on the page where all wallets are showcased. But when you open individual wallets, you'll notice that every single wallet has the name of the latest wallet name update. On certain devices name change doesn't work at all(if the description is unclear I can record a video for you) - this has been fixed by creating a separate view for the  Wallet Name Change,

2. The Android Menu Buttons cover up certain parts of the app on some devices, while on others it's completely okay. Specifically the Wallet Page has the Send and Receive buttons obstructed on some devices. - This has been fixed by the inbuild floating buttom that will dynamically change to adopt the screen size

3. When Sending MAS Tokens, the UX for pasting a Recipient Address is quite confusing. Basically the Application auto-pasted one of your other wallets for convenience. So you need to delete that address from the field and paste the correct one. What happens is the following:

- After pasting the correct one, now you have 2 addresses in front of you: the correct one, and one of your other wallets underneath.
- The user might be confused about what to do, and which address their tokens will be sent to
- Since Massa Mobile Wallet doesn't ask for confirmation before sending a TX, they will feel like they don't know exactly where the tokens are going.

This has been fixed by providing clear instruction for the user to either paste or select an existing wallet. If the existing wallet is selected, its address is automatically pasted in the text field. If for some reasons the user decides to change anything in the text field, the drop down will reset and will not the previouly selected address to void confusing the user.

4. You can't copy wallet addresses from the TX History Page - added the option to copy address from the tx history - although I find it overkilling for a mobile app, especially for small smartphones.

5. When you copy the hash from the TX History Page, it only copies the text visible on the screen, and not the entire hash. Would also be really convenient to open this in the default browser for users when they click on it - this has been fixed to allow copying the full hash.

6. You can't send any tokens besides MAS. If you swap MAS for USDC on Dusa for example, you can't do anything with your USDC. The only other thing you can do is swap them back to MAS if you want to use them - this is out of the current scope - will be added in the future.

7. Dusa works on some devices and on others it doesn't work at all. It shows a "something went wrong screen". Swaps don't work sometimes for people that can open it, and when it does, sometimes a big grey square appears in the transaction section of the wallet  - this is due to insufficient balance to cover the gas fee and the transaction fee - I have improved the error message.

8. On Dusa after swapping USDC to MAS, it still shows that I have USDC on my wallet, when I should have none - this has been fixed.