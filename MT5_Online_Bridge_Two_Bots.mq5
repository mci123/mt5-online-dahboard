// Online dashboard bridge for the existing two-bot demo EA logic.
// Configure BridgeBaseURL and BridgeSecret before compiling.
#property strict
#property version "1.10"
#property description "Online dashboard control bridge - demo only"
#include <Trade/Trade.mqh>
CTrade trade;
input string BridgeBaseURL="https://YOUR-SERVICE.onrender.com";
input string BridgeSecret="REPLACE_WITH_THE_SAME_PRIVATE_DASHBOARD_KEY";
input int PollSeconds=3;
input bool DemoAccountOnly=true;
input int FastEMA_SMC=50,SlowEMA_SMC=200,Lookback=12,ATRPeriod=14;
input int FastEMA_Scalp=9,SlowEMA_Scalp=21,RSIPeriod=14;
input double SMC_RR=2.0,Scalp_RR=1.5,SMC_ATRBuffer=0.25,Scalp_ATRStop=1.5;
input double BuyRSI=55.0,SellRSI=45.0;
input int MaxSpreadPoints=0;
int smcFast,smcSlow,smcAtr,scFast,scSlow,scRsi,scAtr;
bool smcEnabled=true,scalpEnabled=true; double riskPct=1.0; datetime lastBar=0;
ulong smcMagic=61112001,scalpMagic=61112002;
string Base(){string x=BridgeBaseURL;while(StringLen(x)>0&&StringSubstr(x,StringLen(x)-1)=="/")x=StringSubstr(x,0,StringLen(x)-1);return x;}
string EncKey(){return BridgeSecret;}
int Request(string method,string url,string body,char &result[]){char data[];ArrayResize(data,0);if(body!=""){int n=StringToCharArray(body,data,0,WHOLE_ARRAY,CP_UTF8);if(n>0)ArrayResize(data,n-1);}string headers="Content-Type: text/plain\r\n";string responseHeaders="";return WebRequest(method,url,headers,2500,data,result,responseHeaders);}
string Val(string s,string k){string tag=k+"=";int p=StringFind(s,tag);if(p<0)return "";p+=StringLen(tag);int e=StringFind(s,"\n",p);if(e<0)e=StringLen(s);return StringSubstr(s,p,e-p);}
void Sync(){char r[];int c=Request("GET",Base()+"/api/state?key="+EncKey(),"",r);if(c==200){string b=CharArrayToString(r,0,-1,CP_UTF8);string a=Val(b,"SMC"),z=Val(b,"SCALP"),q=Val(b,"RISK");if(a!="")smcEnabled=(a=="1");if(z!="")scalpEnabled=(z=="1");if(q!=""){double v=StringToDouble(q);if(v>=0.1&&v<=2.0)riskPct=v;}}SendStatus();}
void SendStatus(){string b="balance="+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)+"&equity="+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2)+"&positions="+IntegerToString(PositionsTotal())+"&smc="+(smcEnabled?"ON":"OFF")+"&scalp="+(scalpEnabled?"ON":"OFF");char r[];Request("POST",Base()+"/api/status?key="+EncKey(),b,r);}
int OnInit(){if(DemoAccountOnly&&AccountInfoInteger(ACCOUNT_TRADE_MODE)!=ACCOUNT_TRADE_MODE_DEMO)return INIT_FAILED;
 smcFast=iMA(_Symbol,_Period,FastEMA_SMC,0,MODE_EMA,PRICE_CLOSE);smcSlow=iMA(_Symbol,_Period,SlowEMA_SMC,0,MODE_EMA,PRICE_CLOSE);smcAtr=iATR(_Symbol,_Period,ATRPeriod);
 scFast=iMA(_Symbol,_Period,FastEMA_Scalp,0,MODE_EMA,PRICE_CLOSE);scSlow=iMA(_Symbol,_Period,SlowEMA_Scalp,0,MODE_EMA,PRICE_CLOSE);scRsi=iRSI(_Symbol,_Period,RSIPeriod,PRICE_CLOSE);scAtr=iATR(_Symbol,_Period,ATRPeriod);
 if(smcFast==INVALID_HANDLE||smcSlow==INVALID_HANDLE||smcAtr==INVALID_HANDLE||scFast==INVALID_HANDLE||scSlow==INVALID_HANDLE||scRsi==INVALID_HANDLE||scAtr==INVALID_HANDLE)return INIT_FAILED;
 EventSetTimer(MathMax(1,PollSeconds));Sync();return INIT_SUCCEEDED;}
void OnDeinit(const int r){EventKillTimer();IndicatorRelease(smcFast);IndicatorRelease(smcSlow);IndicatorRelease(smcAtr);IndicatorRelease(scFast);IndicatorRelease(scSlow);IndicatorRelease(scRsi);IndicatorRelease(scAtr);}
void OnTimer(){Sync();}
double B(int h,int sh=1){double x[];ArraySetAsSeries(x,true);return CopyBuffer(h,0,sh,1,x)==1?x[0]:0;}
double Hi(int sh,int n){double x=-DBL_MAX;for(int i=sh;i<sh+n;i++)x=MathMax(x,iHigh(_Symbol,_Period,i));return x;}
double Lo(int sh,int n){double x=DBL_MAX;for(int i=sh;i<sh+n;i++)x=MathMin(x,iLow(_Symbol,_Period,i));return x;}
bool Has(ulong m){for(int i=PositionsTotal()-1;i>=0;i--)if(PositionGetTicket(i)>0&&PositionGetString(POSITION_SYMBOL)==_Symbol&&(ulong)PositionGetInteger(POSITION_MAGIC)==m)return true;return false;}
double Lots(double e,double sl){double cash=AccountInfoDouble(ACCOUNT_EQUITY)*riskPct/100.0,ts=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE),tv=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);if(cash<=0||ts<=0||tv<=0||MathAbs(e-sl)<=0)return 0;double raw=cash/((MathAbs(e-sl)/ts)*tv),mn=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN),st=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP),mx=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);if(raw<mn||st<=0)return 0;return NormalizeDouble(MathMin(mx,MathFloor(raw/st)*st),2);}
void OnTick(){datetime t=iTime(_Symbol,_Period,0);if(!t||t==lastBar)return;lastBar=t;if(Bars(_Symbol,_Period)<Lookback+SlowEMA_SMC+5)return;if(MaxSpreadPoints>0&&SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)>MaxSpreadPoints)return;if(smcEnabled)SMC();if(scalpEnabled)Scalp();}
void SMC(){if(Has(smcMagic))return;double f=B(smcFast),s=B(smcSlow),a=B(smcAtr);if(f<=0||s<=0||a<=0)return;double o1=iOpen(_Symbol,_Period,1),c1=iClose(_Symbol,_Period,1),h1=iHigh(_Symbol,_Period,1),l1=iLow(_Symbol,_Period,1),o2=iOpen(_Symbol,_Period,2),c2=iClose(_Symbol,_Period,2),h2=iHigh(_Symbol,_Period,2),l2=iLow(_Symbol,_Period,2),o3=iOpen(_Symbol,_Period,3),c3=iClose(_Symbol,_Period,3),h3=iHigh(_Symbol,_Period,3),l3=iLow(_Symbol,_Period,3);double ph=Hi(3,Lookback),pl=Lo(3,Lookback);bool su=l2<pl&&c2>pl,sd=h2>ph&&c2<ph,bu=c1>Hi(2,Lookback),bd=c1<Lo(2,Lookback),fu=l1>h3,fd=h1<l3,ou=c3<o3,od=c3>o3,tu=f>s&&c1>f,td=f<s&&c1<f;int d=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK),bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);trade.SetExpertMagicNumber(smcMagic);if(su&&bu&&fu&&ou&&tu){double sl=NormalizeDouble(MathMin(l2,l3)-a*SMC_ATRBuffer,d),risk=ask-sl;if(risk<=0)return;double tp=NormalizeDouble(ask+risk*SMC_RR,d),v=Lots(ask,sl);if(v>0)trade.Buy(v,_Symbol,0,sl,tp,"SMC long");}else if(sd&&bd&&fd&&od&&td){double sl=NormalizeDouble(MathMax(h2,h3)+a*SMC_ATRBuffer,d),risk=sl-bid;if(risk<=0)return;double tp=NormalizeDouble(bid-risk*SMC_RR,d),v=Lots(bid,sl);if(v>0)trade.Sell(v,_Symbol,0,sl,tp,"SMC short");}}
void Scalp(){if(Has(scalpMagic))return;double f1=B(scFast,1),f2=B(scFast,2),s1=B(scSlow,1),s2=B(scSlow,2),r=B(scRsi),a=B(scAtr);if(f1<=0||f2<=0||s1<=0||s2<=0||a<=0)return;double c1=iClose(_Symbol,_Period,1),c2=iClose(_Symbol,_Period,2);bool buy=f1>s1&&r>=BuyRSI&&c1>c2&&c1>f1,sell=f1<s1&&r<=SellRSI&&c1<c2&&c1<f1;int d=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK),bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);trade.SetExpertMagicNumber(scalpMagic);if(buy){double sl=NormalizeDouble(ask-a*Scalp_ATRStop,d),risk=ask-sl;if(risk<=0)return;double tp=NormalizeDouble(ask+risk*Scalp_RR,d),v=Lots(ask,sl);if(v>0)trade.Buy(v,_Symbol,0,sl,tp,"Scalper buy");}else if(sell){double sl=NormalizeDouble(bid+a*Scalp_ATRStop,d),risk=sl-bid;if(risk<=0)return;double tp=NormalizeDouble(bid-risk*Scalp_RR,d),v=Lots(bid,sl);if(v>0)trade.Sell(v,_Symbol,0,sl,tp,"Scalper sell");}}
