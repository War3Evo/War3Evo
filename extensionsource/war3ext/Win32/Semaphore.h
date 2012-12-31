/////////////////////////////////////////////////////////////////////
//  Written by Phillip Sitbon
//  Copyright 2003
//
//  Win32/Semaphore.h
//    - Resource counting mechanism
//
/////////////////////////////////////////////////////////////////////
#ifndef _Semaphore_Win32_
#define _Semaphore_Win32_

#include "Win32.h"

#define SEM_VALUE_MAX ((int) ((~0u) >> 1))

class Semaphore
{
public:
  HANDLE S;
  void operator=(const Semaphore &S){}
  Semaphore(const Semaphore &S){}

  
  Semaphore( int init = 0 )
  { S = CreateSemaphore(0,init,SEM_VALUE_MAX,0); }

  virtual ~Semaphore()
  { CloseHandle(S); }

  void Wait() 
  { WaitForSingleObject((HANDLE)S,INFINITE); }

  int Wait_Try() 
  { return ((WaitForSingleObject((HANDLE)S,0)==WAIT_OBJECT_0)?1:0); }

  //post / free
  int Signal() 
  { return (ReleaseSemaphore((HANDLE)S,1,0)?0:ERANGE); }

  //get value
  int Value() const
  { LONG V = -1; ReleaseSemaphore((HANDLE)S,0,&V); return V; }

  void Reset( int init = 0 )
  {
    CloseHandle(S);
    S = CreateSemaphore(0,init,SEM_VALUE_MAX,0);
  }
};

#endif // !_Semaphore_Win32_
