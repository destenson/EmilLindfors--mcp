
# Build the project from the root directory
cargo build --release


cd nsis
# remove dist directory recursively
rm -r dist
mkdir dist
cp ../target/release/client.exe dist/mcp-rs-client.exe
cp ../target/release/server.exe dist/mcp-rs-server.exe

# Run NSIS build installer script
& "C:\Program Files (x86)\NSIS\makensis.exe" mcp-rs-installer.nsi


cd ..
