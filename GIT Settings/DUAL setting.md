

Run this in CMD when new repo is cloned 

for /d %i in ("P:\BSP_LocalDev\Manivannan.Mathialag\zzzz My SAS Files\My GitHub\*") do (
  git -C "%i" config user.name  "coder_mani"
  git -C "%i" config user.email "manivannan.mathi@outlook.com"
)
