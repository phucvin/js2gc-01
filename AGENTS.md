# Agent Instructions

## Memory Recording

You are required to log your interactions.

1.  **Identify Session File**:
    -   A session is defined as a chat session with an agent.
    -   The session file is named using the timestamp of the first interaction in the session using `YYMonDDTHHmm.md` format (e.g., `28Dec26T1559.md` for Dec 26, 2028).
    -   Scan `agents-memory/` to find the existing file for the current session. If no such file exists (i.e., this is the start of a new session), generate a timestamp and create a new file.

2.  **Record Interaction**:
    -   Ensure the file has a summary of the key points at the top.
    -   Append the user's prompt and the agent's response to the session file.
    -   Use the format:
        ```markdown
        Summary: <Summary of key points in this file>

        # User Prompt
        <content>

        # Agent Response
        <content>
        ```

3.  **Submit Changes**:
    -   Always submit or create a PR if there are changes to the `agents-memory` directory.

## Memory Retrieval

When you need to look for useful information in the past, scan the `agents-memory` directory.
