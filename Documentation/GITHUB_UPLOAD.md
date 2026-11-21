# GitHub upload guide

Suggested repository name: `pm-tbl-cancer-asia`.

1. Extract `GitHub_upload_repository_20261120.zip` locally.
2. Create an empty repository on GitHub.
3. Upload the **contents of `pm-tbl-cancer-asia/`**, including `.gitignore` and `.gitattributes`. Upload the actual directory contents, rather than storing the ZIP as the repository's only file.
4. Check that the root README is displayed and that `Code`, `Data`, `Sources`, `Parameters`, and `Documentation` are present.
5. Keep `local-reproduction-data`, `Verification`, the manuscript, reviewer correspondence and historical discussion records outside this public repository unless their intended publication and data permissions have been established.
6. Add the authors' chosen code license if desired; source data have separate terms.

Command-line alternative, run **inside the extracted repository** and replace the URL:

```sh
git init
git add .
git commit -m "Add reproducibility code, frozen WDI inputs and documentation"
git branch -M main
git remote add origin https://github.com/YOUR_ACCOUNT/pm-tbl-cancer-asia.git
git push -u origin main
```

These commands are instructions for the repository owner; the packaging process has not created a remote repository or uploaded anything. No remote account or repository address is assumed.

Public uploads are deliberately compact; no included file exceeds GitHub's single-file limit. The local data ZIP is a separate reproduction attachment, not an instruction to publish licensed datasets.
