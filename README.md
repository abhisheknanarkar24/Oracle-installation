# Oracle-installation
This repository consists oracle installation scripts.

To install oracle on linux, need to follow some prerequisites
1. download linux setup for oracle 12c

2. sudo access should be have to ansible user

3. createrepo package should be installed on target machine.

4. Modified config.ini file: for all parameters which we are passing. 
 Follow Oracle_lin.yml scripts for further exaplanation.

 
ansible-playbook Oracle_lin.yml -e "config file=config.ini hosts= ORA" 
