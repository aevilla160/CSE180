sudo dnf install python openssl pip conda sqlite -y

conda env create -f server/environment.yml
conda activate game-server
conda env list

sudo chmod +x generate-certs.sh
./generate-certs.sh

cp -r certs server/
cp certs/ca-cert.pem client/certs/ca-cert.pem