wget https://noto-website.storage.googleapis.com/pkgs/NotoColorEmoji-unhinted.zip
sudo unzip NotoColorEmoji-unhinted.zip -d /usr/share/fonts/truetype/noto
sudo rm /usr/share/fonts/truetype/noto/LICENSE_OFL.txt
sudo rm /usr/share/fonts/truetype/ancient-scripts/Symbola_hint.ttf
sudo apt-get remove ttf-ancient-fonts-symbola
sudo chmod 644 /usr/share/fonts/truetype/noto/NotoColorEmoji.ttf
fc-cache -f -v
rm NotoColorEmoji-unhinted.zip
