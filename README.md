# Free Download Page Setup

Recommended provider: GitHub Releases for the ZIP file, with GitHub Pages for this static page.

Why this option:

- Free for public repositories.
- Release assets can be under 2 GiB, so a 600 MB ZIP fits.
- GitHub states there is no release bandwidth limit.
- GitHub Pages can host this `index.html` page for free.

Official references:

- GitHub Releases limits: https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases
- GitHub Pages: https://pages.github.com/

## Setup Steps

1. Create or sign into a GitHub account: https://github.com/signup
2. Create a new public repository, for example `download-page`.
3. Upload this `index.html` file to the repository root.
4. Go to repository `Settings` > `Pages`.
5. Set source to `Deploy from a branch`.
6. Choose branch `main` and folder `/root`, then save.
7. Go to `Releases` > `Create a new release`.
8. Create a tag like `v1.0.0`.
9. Upload your 600 MB ZIP as a release asset.
10. Publish the release.
11. Copy the asset URL and replace this placeholder in `index.html`:

```html
https://github.com/USERNAME/REPOSITORY/releases/latest/download/FILENAME.zip
```

The final download URL usually looks like this:

```text
https://github.com/USERNAME/REPOSITORY/releases/latest/download/your-file.zip
```

## Notes

- The ZIP must be public if you want visitors to download it without logging in.
- Do not commit the 600 MB ZIP directly into the Git repository.
- Upload the ZIP only as a GitHub Release asset.
- If you expect extremely high traffic or commercial distribution, use Cloudflare R2 instead.
