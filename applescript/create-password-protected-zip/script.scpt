FasdUAS 1.101.10   ��   ��    k             l   X ����  Q    X  	 
  k   (       l   ��  ��    0 * Prompt the user to choose multiple files.     �   T   P r o m p t   t h e   u s e r   t o   c h o o s e   m u l t i p l e   f i l e s .      r        I   ���� 
�� .sysostdfalis    ��� null��    ��  
�� 
prmp  m       �   � S e l e c t   t h e   f i l e s   y o u   w a n t   t o   i n c l u d e   i n   t h e   p a s s w o r d - p r o t e c t e d   Z I P   f i l e . . .  �� ��
�� 
mlsl  m    ��
�� boovtrue��    o      ���� 0 chosenfiles chosenFiles      l   ��������  ��  ��        l   ��   ��    + % Convert file aliases to POSIX paths.      � ! ! J   C o n v e r t   f i l e   a l i a s e s   t o   P O S I X   p a t h s .   " # " r     $ % $ J    ����   % o      ���� $0 posixchosenfiles posixChosenFiles #  & ' & X    3 (�� ) ( k   $ . * *  + , + r   $ ) - . - n   $ ' / 0 / 1   % '��
�� 
psxp 0 o   $ %���� 0 
chosenfile 
chosenFile . o      ���� "0 posixchosenfile posixChosenFile ,  1�� 1 r   * . 2 3 2 o   * +���� "0 posixchosenfile posixChosenFile 3 n       4 5 4  ;   , - 5 o   + ,���� $0 posixchosenfiles posixChosenFiles��  �� 0 
chosenfile 
chosenFile ) o    ���� 0 chosenfiles chosenFiles '  6 7 6 l  4 4��������  ��  ��   7  8 9 8 l  4 4�� : ;��   : , & Define the destination ZIP file path.    ; � < < L   D e f i n e   t h e   d e s t i n a t i o n   Z I P   f i l e   p a t h . 9  = > = r   4 A ? @ ? I  4 =���� A
�� .sysonwflfile    ��� null��   A �� B C
�� 
prmt B m   6 7 D D � E E ~ C h o o s e   a   n a m e   a n d   l o c a t i o n   f o r   t h e   p a s s w o r d - p r o t e c t e d   Z I P   f i l e : C �� F��
�� 
dfnm F m   8 9 G G � H H  A r c h i v e . z i p��   @ o      ���� 0 zipfilepath zipFilePath >  I J I l  B B��������  ��  ��   J  K L K l  B B�� M N��   M 1 + Convert the ZIP file path to a POSIX path.    N � O O V   C o n v e r t   t h e   Z I P   f i l e   p a t h   t o   a   P O S I X   p a t h . L  P Q P r   B K R S R n   B G T U T 1   E G��
�� 
psxp U o   B E���� 0 zipfilepath zipFilePath S o      ���� $0 posixzipfilepath posixZipFilePath Q  V W V l  L L��������  ��  ��   W  X Y X l  L L�� Z [��   Z + % Prompt the user to enter a password.    [ � \ \ J   P r o m p t   t h e   u s e r   t o   e n t e r   a   p a s s w o r d . Y  ] ^ ] I  L p�� _ `
�� .sysodlogaskr        TEXT _ m   L O a a � b b D E n t e r   a   p a s s w o r d   f o r   t h e   Z I P   f i l e : ` �� c d
�� 
dtxt c m   R U e e � f f   d �� g h
�� 
btns g J   X ` i i  j k j m   X [ l l � m m  C a n c e l k  n�� n m   [ ^ o o � p p  O K��   h �� q r
�� 
dflt q m   c f s s � t t  O K r �� u��
�� 
htxt u m   i j��
�� boovtrue��   ^  v w v r   q | x y x n   q x z { z 1   t x��
�� 
ttxt { l  q t |���� | 1   q t��
�� 
rslt��  ��   y o      ���� 0 zippassword zipPassword w  } ~ } l  } }��������  ��  ��   ~   �  l  } }�� � ���   � , & Only runs if ZIP password is defined.    � � � � L   O n l y   r u n s   i f   Z I P   p a s s w o r d   i s   d e f i n e d . �  � � � Z   }& � ��� � � >  } � � � � o   } ����� 0 zippassword zipPassword � m   � � � � � � �   � k   � � �  � � � r   � � � � � n  � � � � � I   � ��� ����� (0 joinlistwithquotes joinListWithQuotes �  � � � o   � ����� $0 posixchosenfiles posixChosenFiles �  ��� � m   � � � � � � �   ��  ��   �  f   � � � o      ���� 0 
filestozip 
filesToZip �  � � � l  � ���������  ��  ��   �  � � � l  � ��� � ���   �   Shell script logic.    � � � � (   S h e l l   s c r i p t   l o g i c . �  � � � I  � ��� ���
�� .sysoexecTEXT���     TEXT � b   � � � � � b   � � � � � b   � � � � � b   � � � � � b   � � � � � m   � � � � � � �  z i p   - P   � o   � ����� 0 zippassword zipPassword � m   � � � � � � � 
   - r j   � o   � ����� $0 posixzipfilepath posixZipFilePath � m   � � � � � � �    � o   � ����� 0 
filestozip 
filesToZip��   �  � � � l  � ���������  ��  ��   �  � � � l  � ��� � ���   � ( " Delay after running script logic.    � � � � D   D e l a y   a f t e r   r u n n i n g   s c r i p t   l o g i c . �  � � � I  � ��� ���
�� .sysodelanull��� ��� nmbr � m   � ����� ��   �  � � � l  � ���������  ��  ��   �  � � � l  � ��� � ���   � 6 0 Check if the zip file was created successfully.    � � � � `   C h e c k   i f   t h e   z i p   f i l e   w a s   c r e a t e d   s u c c e s s f u l l y . �  ��� � Z   � � ��� � � =  � � � � � l  � � ����� � I  � ��� ���
�� .sysoexecTEXT���     TEXT � b   � � � � � b   � � � � � m   � � � � � � � 
 [   - e   � n   � � � � � 1   � ���
�� 
strq � o   � ����� $0 posixzipfilepath posixZipFilePath � m   � � � � � � � B   ]   & &   e c h o   ' t r u e '   | |   e c h o   ' f a l s e '��  ��  ��   � m   � � � � � � �  t r u e � I  � ��� � �
�� .sysodlogaskr        TEXT � m   � � � � � � � < Z I P   f i l e   c r e a t e d   s u c c e s s f u l l y ! � �� � �
�� 
btns � J   � � � �  ��� � m   � � � � � � �  O K��   � �� ���
�� 
dflt � m   � � � � � � �  O K��  ��   � I  ��� � �
�� .sysodlogaskr        TEXT � m   � � � � � � � 0 E r r o r   c r e a t i n g   Z I P   f i l e . � �� � �
�� 
btns � J   � � � �  ��� � m   � � � � � � �  O K��   � �� � �
�� 
dflt � m   � � � � � � �  O K � �� ���
�� 
disp � m   � ��
�� stic    ��  ��  ��   � I 	&�� � �
�� .sysodlogaskr        TEXT � m  	 � � � � � \ E r r o r   c r e a t i n g   Z I P   f i l e .   P a s s w o r d   i s   r e q u i r e d . � �� � �
�� 
btns � J   � �  ��� � m   � � � � �  O K��   � �� � 
�� 
dflt � m   �  O K  ����
�� 
disp m   ��
�� stic    ��   � �� l ''��������  ��  ��  ��   	 R      ����
�� .ascrerr ****      � **** o      ���� 0 errmsg errMsg��   
 Z  0X���� H  06 E  05	
	 o  01���� 0 errmsg errMsg
 m  14 �  U s e r   c a n c e l e d . I 9T��
�� .sysodlogaskr        TEXT o  9:�� 0 errmsg errMsg �~
�~ 
btns J  =B �} m  =@ �  O K�}   �|
�| 
dflt m  EH �  O K �{�z
�{ 
disp m  KN�y
�y stic    �z  ��  ��  ��  ��     l     �x�w�v�x  �w  �v    l     �u�u   &   Join list with quotes function.    �   @   J o i n   l i s t   w i t h   q u o t e s   f u n c t i o n . !"! i     #$# I      �t%�s�t (0 joinlistwithquotes joinListWithQuotes% &'& o      �r�r 0 thelist theList' (�q( o      �p�p 0 	delimiter  �q  �s  $ k     :)) *+* r     ,-, m     .. �//  - o      �o�o 0 	theresult 	theResult+ 010 Y    72�n34�m2 k    255 676 r    898 b    :;: b    <=< b    >?> o    �l�l 0 	theresult 	theResult? m    @@ �AA  "= n    BCB 4    �kD
�k 
cobjD o    �j�j 0 i  C o    �i�i 0 thelist theList; m    EE �FF  "9 o      �h�h 0 	theresult 	theResult7 G�gG Z    2HI�f�eH >   &JKJ o     �d�d 0 i  K l    %L�c�bL I    %�aM�`
�a .corecnte****       ****M o     !�_�_ 0 thelist theList�`  �c  �b  I r   ) .NON b   ) ,PQP o   ) *�^�^ 0 	theresult 	theResultQ o   * +�]�] 0 	delimiter  O o      �\�\ 0 	theresult 	theResult�f  �e  �g  �n 0 i  3 m    �[�[ 4 I   �ZR�Y
�Z .corecnte****       ****R o    	�X�X 0 thelist theList�Y  �m  1 S�WS L   8 :TT o   8 9�V�V 0 	theresult 	theResult�W  " U�UU l     �T�S�R�T  �S  �R  �U       �QVWX�Q  V �P�O�P (0 joinlistwithquotes joinListWithQuotes
�O .aevtoappnull  �   � ****W �N$�M�LYZ�K�N (0 joinlistwithquotes joinListWithQuotes�M �J[�J [  �I�H�I 0 thelist theList�H 0 	delimiter  �L  Y �G�F�E�D�G 0 thelist theList�F 0 	delimiter  �E 0 	theresult 	theResult�D 0 i  Z .�C@�BE
�C .corecnte****       ****
�B 
cobj�K ;�E�O 2k�j kh ��%��/%�%E�O��j  
��%E�Y h[OY��O�X �A\�@�?]^�>
�A .aevtoappnull  �   � ****\ k    X__  �=�=  �@  �?  ] �<�;�< 0 
chosenfile 
chosenFile�; 0 errmsg errMsg^ ?�: �9�8�7�6�5�4�3�2�1�0�/ D�. G�-�,�+ a�* e�) l o�( s�'�&�%�$�#�" � ��!�  � � ��� �� � � � � � � � ���� � ���
�: 
prmp
�9 
mlsl�8 
�7 .sysostdfalis    ��� null�6 0 chosenfiles chosenFiles�5 $0 posixchosenfiles posixChosenFiles
�4 
kocl
�3 
cobj
�2 .corecnte****       ****
�1 
psxp�0 "0 posixchosenfile posixChosenFile
�/ 
prmt
�. 
dfnm
�- .sysonwflfile    ��� null�, 0 zipfilepath zipFilePath�+ $0 posixzipfilepath posixZipFilePath
�* 
dtxt
�) 
btns
�( 
dflt
�' 
htxt�& 
�% .sysodlogaskr        TEXT
�$ 
rslt
�# 
ttxt�" 0 zippassword zipPassword�! (0 joinlistwithquotes joinListWithQuotes�  0 
filestozip 
filesToZip
� .sysoexecTEXT���     TEXT
� .sysodelanull��� ��� nmbr
� 
strq
� 
disp
� stic    � � 0 errmsg errMsg�  �>Y**���e� E�OjvE�O �[��l 	kh  ��,E�O��6F[OY��O*����� E` O_ �,E` Oa a a a a a lva a a ea  O_ a ,E`  O_  a ! �)�a "l+ #E` $Oa %_  %a &%_ %a '%_ $%j (Okj )Oa *_ a +,%a ,%j (a -  a .a a /kva a 0� Y a 1a a 2kva a 3a 4a 5a 6 Y a 7a a 8kva a 9a 4a 5a 6 OPW /X : ;�a <  �a a =kva a >a 4a 5a 6 Y hascr  ��ޭ