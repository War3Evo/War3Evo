#ifndef __OWNAGEHEADERSTD
#define __OWNAGEHEADERSTD

//ONLY INCLUDE THIS FILE AFTER SM INCLUDES HAVE BEEN INCLUDED
//otherwise this file doesnt know what ISourceMod *g_pSM is


#include <iostream>//need this, incase they didnt include it, need for cout<<endl
#include <stdio.h>
#include <stdarg.h>
#include <string>
#include <vector>


//standard prints
#ifndef PRINT
#define PRINT printf
#endif
#ifndef CPRINT
#define CPRINT std::cout <<
#endif

#define FORMAT g_pSM->Format
//end standard prints

#define DP PRINT

//extern needs to stay outside of anoy-namespace
extern ISourceMod *g_pSM;
extern IExtension *myself;



namespace //anoynamous namespace,
	//these funcs are only accisible by the cpp files that included this file.
	//however, that means you have duplicate code...its a trade off for ease of use
{
	cell_t dummy;

	using namespace std;


	//prototypes
	void ERRS(char* ,...);
	void ERRS(char* ,...);
	size_t UTIL_Format(char *buffer, size_t maxlength, const char *fmt, va_list params);
	bool GetInterface(char* interf,SMInterface** pointer,bool quitifnotfound=false);

	void ERRS(char* format,...)
	{
		va_list ap;
		va_start(ap, format);


		char buffer[2000];
		UTIL_Format(buffer,sizeof(buffer),format,ap);
		g_pSM->LogError(myself,buffer);
		//fprintf(g->log,"[W3E] %s\n",buffer);
		va_end(ap);
	}

	size_t UTIL_Format(char *buffer, size_t maxlength, const char *fmt, va_list params)
	{
		size_t len = vsnprintf(buffer, maxlength, fmt, params);

		if (len >= maxlength)
		{
			len = maxlength - 1;
			buffer[len] = '\0';
		}

		return len;
	}

	//helper for getting a sm interface
	bool GetInterface(char* interf,SMInterface** pointer,bool quitifnotfound){
		//PRINT("[war3dll] try to get")<<interf<< std::endl;
		if(!(g_pShareSys->RequestInterface(interf,0,myself,pointer))){
			CPRINT("[war3ext] could not get sm interface ")<<interf<< std::endl;
			if(quitifnotfound){
				for(int i=0;i<100;i++){
					ERRS("could not get sm interface %s",interf);
				}
				exit(0);
			}
			return false;
		}
		else if(*pointer!=NULL){
			CPRINT("[war3ext] got interface ")<<interf<< std::endl;
			return true;
		}
		return false;
	}

	void explode(vector<string> &results,string str, string separator ){
		size_t found;
		found = str.find(separator); //find searches multiple character sequence, unlike find first of which is any match
		while(found != string::npos){
			if(found > 0){
				results.push_back(str.substr(0,found));
			}
			str = str.substr(found+separator.length());
			found = str.find(separator);
		}
		if(str.length() > 0){
			results.push_back(str);
		}
	}
	string replacestr(string &str,string find,string replacewith){
		size_t findlength=find.length();
		size_t replacewithlen=replacewith.length();

		size_t pos=0;
		do{
			pos=str.find(find,pos);
			//ERRS("pos %d",pos);
			if(pos!=string::npos){
				str=str.replace(pos,findlength,replacewith);
				pos+=replacewithlen;
				//ERRS("str is now %s",str.c_str());
			}
		}
		while(pos!=string::npos);
		//ERRS("returning %s",str.c_str());
		return str;
	}
	void ToLower(string &a_str){
		int size=a_str.size();
		for ( int ix = 0; ix<size; ix++)
		{
				a_str[ix] = tolower( (unsigned char) a_str[ix] );
		}
	}
	void ToLower(char* a_str){
		for ( int ix = 0; a_str[ix] != '\0'; ix++)
		{
				a_str[ix] = tolower( (unsigned char) a_str[ix] );
		}
	}
	bool strequal(string aa,string bb,bool insensitive=true){
		string a = string(aa);
		string b = string(bb);
		if(insensitive){
			ToLower(a);
			ToLower(b);
		}
		return a==b;
	}
	bool strequal(char* aa,char* bb,bool insensitive=true){
		string a = string(aa);
		string b = string(bb);
		if(insensitive){
			ToLower(a);
			ToLower(b);
		}
		return a==b;
	}
	bool strequal2(char* aa,char* bb,bool insensitive=true){ //make VC stfu about infinite recursion
		return strequal(aa,bb,insensitive);
	}
	
	bool strequal(string a,char* b,bool insensitive=true){
		return strequal2(  (char*)a.c_str()   ,b,insensitive);
	}
	bool strequal(char*  a,string b,bool insensitive=true){
		return strequal2(a,  (char*) b.c_str()   ,insensitive);
	}
	//using namespace boost;
	//void ocsplit(vector<string> &explodedz,string &line,char* delimiter){
	//	iter_split(explodedz,line,first_finder(delimiter));
	//}
	void strncpys(char* dest,int num,char* source){
		std::strncpy(dest,source,num-2);
		dest[num-1]=0;

	}
	//to be safe num = 16, then 15 characters can be stored
	bool strtruncate(char * src,int num){
		num--; //if its 16, we null at index 15
		int i=0;
		while(i<=num){ //check the 15th index also
			if(src[i]==0){
				return false;
			}
			i++;
		}
		src[num]=0;
		return true;
	}

	using namespace std;
	int strtoint(const char* input){
		return atoi(input);
	}


}



#endif

