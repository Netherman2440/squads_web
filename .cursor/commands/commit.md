# Generate commit message and description for current staged git changes

Analyze the staged git changes and the last 3 commits to understand context and intent.
Use this structure for the answer:

Commit message:
```
<One line commit message>
```

Commit description:
```
<Description of the changes>
- Explain what was changed using a clear list format
```

To provide you the context, here are the relevant data:

--- GIT STATUS ---
$(git status --short)

--- LAST 3 COMMITS ---
$(git log -3 --oneline)

--- STAGED CHANGES ---
$(git diff --cached)

--- UNSTAGED CHANGES ---
$(git diff)

Use read tool to analyze the context and intent of the changes.
