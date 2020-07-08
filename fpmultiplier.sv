module fpmultiplier (
 output logic [31:0] product, 
 output logic ready, 
 input logic [31:0] a, 
 input logic clock, nreset); // to allow inputs to be loaded in succession

 logic[31:0] float_a;                           
 logic[31:0] float_b;
 logic s3;
 logic s1,s2;                                      
 logic[7:0] exp1,exp2,exp3;                              
 logic[22:0] man1,man2,man3; 
 logic [1:0] inf, zero, NaN;
 logic n;
 //logic[7:0] temp1;
 //logic[7:0] temp2;
 //logic[8:0] temp3;
 logic[23:0] temp;
 logic[45:0] comeout;
 logic[23:0] all;                
 logic[1:0] zheng;               
 logic flag;

enum {start, loada, checka, loadb, checkb, x, y, judge, judge1, e, b, c, man, exp, last, d} state;


always @(posedge clock, negedge nreset) 
if ( ~nreset)
   begin
 
 state <= start; 
 end
else 
begin
// This is a state machine, but there are other ways to do this

case (state) 
 start : begin
	s1<=1'b0;
        exp1<=8'b00000000;
        man1<=23'd0;

 	s2<=1'b0;
        exp2<=8'b00000000;
        man2<=23'd0;
	flag<=0;
	zero<=2'b00;
 	NaN<=2'b00;
 	inf<=2'b00;
 	product<=32'd0;

  	state <= loada;
$display("state=start");
  end 
 loada : begin
  	float_a <= a; 	

 	state <= loadb;
$display("state=loada");
  end

 loadb : begin
$display("float_a=%b, exp1=%b",float_a,exp1);
  	float_b <= a;

	state <= x;
$display("state=loadb");
  end
 x:begin
     	s1<=float_a[31];
      	exp1<=float_a[30:23];
       	man1<=float_a[22:0];

	state <= y;
end

 y:begin
 	s2<=float_b[31];
       	exp2<=float_b[30:23];
      	man2<=float_b[22:0];

	state <= checka;
end

checka : begin
$display("float_b=%b, exp2=%b",float_b,exp2);

  if(exp1==8'd255 && man1==23'd0) //+-inf
   inf[0] <= 1'b1;
  else if(exp1==8'd255 && man1!=23'd0) //NaN
   NaN[0] <= 1'b1;
  else if(exp1==8'd0 && man1==23'd0) //zero
   zero[0] <= 1'b1;
  else ;

	state<=checkb;
$display("state=checka");
end

 checkb : begin
  if(exp2==8'd255 && man2==23'd0 ) //+-inf
   inf <= {1'b1,inf[0]};
  else if(exp2==8'd255 && man2!=23'd0) //NaN
   NaN <= {1'b1 ,NaN[0]}; 
  else if(exp2==8'd0 && man2==23'd0) //zero
   zero <= {1'b1,zero[0]};

   state <= judge;
$display("state=checkb");
end

 judge : begin
$display("zero=%b,inf=%b,NaN=%b",zero,inf,NaN);
  if(NaN!=2'b00)
  	begin product<={1'b0,8'd255,23'b01010100101010001010010};flag<=1;end //any num*NaN;output=NaN
  else if((zero[0]==1||zero[1]==1) && (inf[0]==1||inf[1]==1)) //zero*inf;inf*zero
  	begin product<={1'b0,8'd255,23'b01010100101010001010010}; flag<=1;end //output=NaN
  else if(zero!=2'b00)          //zero*zero;zero*vaild;vaild*zero;output=zero
  	begin product<=32'd0; flag<=1;/*$display("product=%b",product);*/end
  else if((inf != 2'b00))       //inf*vaild;vaild*inf;inf*inf;output=inf
	begin product<=32'b01111111100000000000000000000000; flag<=1;end 

	state<=judge1;
$display("state=judge");
end

 judge1 : begin   
	if(flag)
		state <= start;
	else   
		state <= man;
	$display("state=judge1");
 end

 man : begin
       if(man1==23'b0000000000_0000000000000)
         begin
           man3<=man1;
           n<=1'b0;
state <= exp;
         end
             else if(man2==23'b0000000000_0000000000000)
             begin
               man3<=man2;
               n<=1'b0;
		state <= exp;
             end                            
              else
              begin
              comeout<=man1*man2;
              temp<=man1+man2;                  //1.m*1.n=1+(0.m+0.n)+(0.m*0.n)
 	      state <= e;
 	      end
$display("state=man");
       end
       e : begin   
	   all<=temp[22:0]+comeout[45:23]; 
		state <= b;
$display("state=e");
	   end  
       b : begin
	   zheng<=1'b1+temp[23]+all[23];
		state <= c;
$display("state=b");
	end
                  
c : begin
          if(zheng[1]==1)            
          begin
               n<=1'b1;                     
              if(zheng[0]==1)                   
               man3[22:0]<={1'b1,all[22:1]};    
              else
               man3[22:0]<={1'b0,all[22:1]};
           end
              else 
              begin
               n<=1'b0;
            man3<=all[22:0];
    	      end
      
   state <= exp;
$display("state=c");
  end

 exp : begin
  	exp3<=exp1+exp2-8'd127+n; 
 
      	state <= last;  
$display("state=exp");
      end

 last : begin
   	s3<=s1^s2;
         
        state<=d;
$display("state=last");
         end
 d : begin
    	product<={s3,exp3[7:0],man3[22:0]};
 
        state <= start;
	
$display("state=d");
        end

endcase
end


always @(*)
begin ready = (state == start); $display("ready=%b",ready);end

endmodule
