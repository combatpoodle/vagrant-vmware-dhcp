rvm use 2.0.0@da-vmware-network --create

rake build

cp pkg/* ~/gemrepo/gems/
(
cd ~/gemrepo/gems
gem generate_index
)
