	.data
komunikat: .asciiz "Podaj kat w stopniach 0-180\n"
sin:	.asciiz "\nsin: "
cos:	.asciiz "\ncos: "
atan:	.word 0x2ed03993, 0x1ba2b379, 0xe9a13e7, 0x76981b2, 0x3b86f79, 0x1dcae99, 0xee6630, 0x7734f5, 0x3b9ab6, 0x1dcd62, 0xee6b2
Kn:	.word 607252935, 707106781, 632455532, 613571991, 608833912, 607648256, 607351770, 607277644, 607259112, 607254479, 607253321, 607253031, 607252959, 607252941, 607252936
Pi_d180:.word 0x010a50ec
#alfa:	.word 523598775
x:	.word 1000000000 #nie wiadomo jakie K dac na poczatku	
y:	.word 0	#wg CORDIC	


		#wszystko przemnozone * 10^9 wiecej nie bo dla pewnych wartosci moze wyleciec poza zakres
	.text
	.globl main
main: 	li $v0, 4
	la $a0, komunikat
	syscall
	li $v0, 5
	syscall  # komunikat
	li $t0,90 
	slti $s3, $v0,90
	
	div $v0,$t0 #modulo
	mfhi $v0
	lw $t0, Pi_d180
	mulo $t0, $v0, $t0
	mflo $s0 # z
	
	lw $s1, x # x
	lw $s2, y # y
	la $s7, atan # eps
	li $t7, 0 # k
	
	beqz $s0, wynik #od razu do petli 2

petla1:	
	srav $t1, $s2, $t7 #y>>k
	srav $t2, $s1, $t7 #x>>k
	lw $t3, ($s7) #t3=atan[k]
	add $t0, $t3, $zero # na wypadek negacji
	addi $s7, $s7, 4 #atan++
	slt $s4, $s0, $zero #jesli z <0 to d=1
	beqz $s4, oblicz1 #jesli d=0 to -> oblicz1
	neg $t0, $t0 #neguje w zaleznosci od d
	neg $t1, $t1
	neg $t2, $t2

oblicz1:	
	sub $s1, $s1, $t1 #x=x-y>>k
	add $s2, $s2, $t2 #y=y+x>>k
	sub $s0, $s0, $t0 #z=z-atan
	addi $t7, $t7, 1 #k++
	slti $t6, $t7, 11 # k < 11
	sne $t5, $s0, $zero #  z nie 0 
	and $t4, $t5, $t6 # z && k <11
	bnez $t4, petla1 # kolejna iteracja jesli jw. 
	
	beqz $t5, wynik #jesli z=0 to skacz do wynik

petla2:
	srav $t1, $s2, $t7 #y>>k
	srav $t2, $s1, $t7 #x>>k
	sra $t3, $t3, 1 #atan/2 
	add $t0, $t3, $zero #move t0 do t3
	slt $s4, $s0, $zero #jesli z<0 to d=1
	beqz $s4, oblicz2 #jesli =0 to oblicz2
	neg $t0, $t0 #negacja
	neg $t1, $t1
	neg $t2, $t2

oblicz2:	
	sub $s1, $s1, $t1 # x = x - y>>k
	add $s2, $s2, $t2 # y = y + x>>k
	sub $s0, $s0, $t0 # z = z - atan
	addi $t7, $t7, 1 # k++
	sne $t6, $t0, $zero # czy atan jest zero jesli nie to t6=1
	sne $t5, $s0, $zero # czy z jest 0 jesli nie to t5=1
	and $t4, $t5, $t6 # warunek pêtli
	bnez $t4, petla2 # wroc
	
wynik:	
	la $t8, Kn # laduj Kn
	slti $t6, $t7, 10 # k < 14
	beqz $t6, ustawK
	sll $t7, $t7, 2
	add $t8, $t8, $t7

ustawK:	
	li $v0, 4
	la $a0, sin
	syscall
	lw $t9, ($t8) # pierwszy wyraz Kn
	multu $s2, $t9 # y*Kn
	mfhi $t0 
	mflo $t1
	bgez $t1, dodatnia1
	neg $t1,$t1

dodatnia1:
	sll $t0, $t0, 2
	sra $t1, $t1, 30
	or $a0, $t0, $t1
	sra $a0, $a0, 10
	mulo $a0, $a0, 1099
	li $v0, 1
	syscall
	
	li $v0, 4
	la $a0, cos
	syscall
	multu $s1, $t9 # x*Kn
	mfhi $t0 
	mflo $t1
	bgez $t1, dodatnia2
	neg $t1,$t1

dodatnia2:
	sll $t0, $t0, 2
	sra $t1, $t1, 30
	or $a0, $t0, $t1
	sra $a0, $a0, 11
	mulo $a0, $a0, 2199
	beqz $s3,ujemna
	li $v0, 1
	syscall

exit:	li $v0, 10
	syscall

ujemna:
	sub $a0,$zero,$a0
	li $v0,1
	syscall
exit2:	li $v0, 10
	syscall
