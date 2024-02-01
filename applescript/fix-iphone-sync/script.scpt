FasdUAS 1.101.10   ��   ��    k             l     ����  r       	  J      
 
     m        �   . A M P D e v i c e D i s c o v e r y A g e n t      m       �    A M P L i b r a r y A g e n t      m       �   " M D C r a s h R e p o r t T o o l   ��  m       �   & M o b i l e D e v i c e U p d a t e r��   	 o      ���� 0 	processes  ��  ��        l  	  ����  r   	     J   	 ����    o      ���� "0 killedprocesses killedProcesses��  ��         l     ��������  ��  ��      ! " ! l     �� # $��   # 0 * Loop through all the suspected processes.    $ � % % T   L o o p   t h r o u g h   a l l   t h e   s u s p e c t e d   p r o c e s s e s . "  & ' & l   K (���� ( X    K )�� * ) k    F + +  , - , l   �� . /��   . W Q If "pgrep" returns a process number, this will return zero (assuming no errors).    / � 0 0 �   I f   " p g r e p "   r e t u r n s   a   p r o c e s s   n u m b e r ,   t h i s   w i l l   r e t u r n   z e r o   ( a s s u m i n g   n o   e r r o r s ) . -  1 2 1 r    + 3 4 3 c    ) 5 6 5 l   ' 7���� 7 I   '�� 8��
�� .sysoexecTEXT���     TEXT 8 b    # 9 : 9 b    ! ; < ; m     = = � > >  p g r e p   < o     ���� 0 process   : m   ! " ? ? � @ @ *   >   / d e v / n u l l ;   e c h o   $ ?��  ��  ��   6 m   ' (��
�� 
long 4 o      ���� 0 	isrunning 	isRunning 2  A B A l  , ,��������  ��  ��   B  C D C l  , ,�� E F��   E 0 * Check if the current process is running.	    F � G G T   C h e c k   i f   t h e   c u r r e n t   p r o c e s s   i s   r u n n i n g . 	 D  H�� H Z   , F I J���� I =   , / K L K o   , -���� 0 	isrunning 	isRunning L m   - .����   J k   2 B M M  N O N l  2 2�� P Q��   P   Kill the process.    Q � R R $   K i l l   t h e   p r o c e s s . O  S T S I  2 9�� U��
�� .sysoexecTEXT���     TEXT U b   2 5 V W V m   2 3 X X � Y Y  k i l l a l l   - 9   W o   3 4���� 0 process  ��   T  Z [ Z l  : :��������  ��  ��   [  \ ] \ l  : :�� ^ _��   ^ / ) Record that the process has been killed.    _ � ` ` R   R e c o r d   t h a t   t h e   p r o c e s s   h a s   b e e n   k i l l e d . ]  a�� a r   : B b c b c   : ? d e d o   : ;���� 0 process   e m   ; >��
�� 
TEXT c n       f g f  ;   @ A g o   ? @���� "0 killedprocesses killedProcesses��  ��  ��  ��  �� 0 process   * o    ���� 0 	processes  ��  ��   '  h i h l     ��������  ��  ��   i  j k j l     �� l m��   l < 6 Convert the lists into a displayable list for dialog.    m � n n l   C o n v e r t   t h e   l i s t s   i n t o   a   d i s p l a y a b l e   l i s t   f o r   d i a l o g . k  o p o l  L S q���� q r   L S r s r m   L O t t � u u   s o      ���� .0 killedprocessesstring killedProcessesString��  ��   p  v w v l     ��������  ��  ��   w  x y x l     �� z {��   z . ( Set the killed processes into a string.    { � | | P   S e t   t h e   k i l l e d   p r o c e s s e s   i n t o   a   s t r i n g . y  } ~ } l  T z ����  X   T z ��� � � r   d u � � � b   d q � � � b   d o � � � b   d k � � � o   d g���� .0 killedprocessesstring killedProcessesString � o   g j��
�� 
ret  � m   k n � � � � �  -   � o   o p���� 0 killedprocess killedProcess � o      ���� .0 killedprocessesstring killedProcessesString�� 0 killedprocess killedProcess � o   W X���� "0 killedprocesses killedProcesses��  ��   ~  � � � l     ��������  ��  ��   �  � � � l  { � ����� � Z   { � � ��� � � =   { � � � � o   { ~���� .0 killedprocessesstring killedProcessesString � m   ~ � � � � � �   � I  � ��� � �
�� .sysodlogaskr        TEXT � m   � � � � � � � � S o r r y !   T h e r e   d o e s n ' t   s e e m   t o   b e   a n y   s t u c k   p r o c e s s e s   a f f e c t i n g   y o u r   i P h o n e   s y n c i n g . � �� � �
�� 
btns � J   � � � �  ��� � m   � � � � � � �  O K��   � �� ���
�� 
dflt � m   � � � � � � �  O K��  ��   � I  � ��� ���
�� .sysodlogaskr        TEXT � c   � � � � � b   � � � � � b   � � � � � m   � � � � � � � � i P h o n e   s y n c i n g   s h o u l d   n o w   b e   u n s t u c k .   H e r e   a r e   a   l i s t   o f   p r o c e s s e s   t h a t   a r e   t e r m i n a t e d : � o   � ���
�� 
ret  � o   � ����� .0 killedprocessesstring killedProcessesString � m   � ���
�� 
TEXT��  ��  ��   �  ��� � l     ��������  ��  ��  ��       �� � ���   � ��
�� .aevtoappnull  �   � **** � �� ����� � ���
�� .aevtoappnull  �   � **** � k     � � �   � �   � �  & � �  o � �  } � �  �����  ��  ��   � ������ 0 process  �� 0 killedprocess killedProcess �     ������������ = ?������ X�� t���� � � ��� ��� ��� ��� �� 0 	processes  �� "0 killedprocesses killedProcesses
�� 
kocl
�� 
cobj
�� .corecnte****       ****
�� .sysoexecTEXT���     TEXT
�� 
long�� 0 	isrunning 	isRunning
�� 
TEXT�� .0 killedprocessesstring killedProcessesString
�� 
ret 
�� 
btns
�� 
dflt
�� .sysodlogaskr        TEXT�� ������vE�OjvE�O <�[��l 	kh  �%�%j �&E�O�j  �%j O�a &�6FY h[OY��Oa E` O %�[��l 	kh _ _ %a %�%E` [OY��O_ a   a a a kva a � Y a _ %_ %a &j  ascr  ��ޭ