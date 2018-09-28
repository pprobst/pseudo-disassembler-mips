# pseudo-disassembler-mips
A binary instruction disassembler written in MIPS Assembly.

This program was an assigntment for my Computer Organization class of 2017/2.

* To generate the output file ```output.txt```, simply compile and execute 
  ```t1-disassembler.s``` in [MARS](http://courses.missouristate.edu/KenVollmar/mars/);

* The file (program) to be translated must have the name ```input.bin```; 
  such file can be obtained by using the MARS memory dump tool in 
  any Assembly MIPS source code. See ```input.bin```.

##### Observations: 
* The source code comments are all written in Portuguese;
* Not all MIPS instructions are compatible (e.g. float instructions).
