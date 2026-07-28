cat << 'EOF' > force144.sh
#!/system/bin/sh

echo "Setting Refresh Rate to 144Hz..."

settings put system min_refresh_rate 144.0
settings put system peak_refresh_rate 144.0
settings put global user_refresh_rate 144
settings put global peak_refresh_rate 144.0

setprop persist.sys.game.fps 144
settings put system user_refresh_rate 144

echo "Done! Current Peak Refresh Rate:"
settings get system peak_refresh_rate

EOF
chmod +x force144.sh
