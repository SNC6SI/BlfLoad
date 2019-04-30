
#include "mex.h"
#include <tchar.h>                     /* RTL   */
#include <stdio.h>

#define STRICT                         /* WIN32 */
#include <windows.h>

#include "binlog.h"                    /* BL    */

int read_statistics(LPCTSTR pFileName, VBLFileStatisticsEx* pstatistics)
{
    HANDLE hFile;
    BOOL bSuccess;
    hFile = BLCreateFile( pFileName, GENERIC_READ);

    if ( INVALID_HANDLE_VALUE == hFile)
    {
        return -1;
    }

    BLGetFileStatisticsEx( hFile, pstatistics);
    
    if ( !BLCloseHandle( hFile))
    {
        return -1;
    }

    return bSuccess ? 0 : -1;
}



int read_info( LPCTSTR pFileName, LPDWORD pRead, double* candata_, double* canmsgid_, double* canchannel_)
{
    HANDLE hFile;
    VBLObjectHeaderBase base;
    VBLCANMessage message;
    VBLCANMessage2 message2;
    unsigned int i;

    BOOL bSuccess;

    if ( NULL == pRead)
    {
        return -1;
    }

    *pRead = 0;

    /* open file */
    hFile = BLCreateFile( pFileName, GENERIC_READ);

    if ( INVALID_HANDLE_VALUE == hFile)
    {
        return -1;
    }


    bSuccess = TRUE;
    
    /* read base object header from file */
    while ( bSuccess && BLPeekObject( hFile, &base))
    {
        switch ( base.mObjectType)
        {
        case BL_OBJ_TYPE_CAN_MESSAGE:
            /* read CAN message */
            message.mHeader.mBase = base;
            bSuccess = BLReadObjectSecure( hFile, &message.mHeader.mBase, sizeof(message));
            /* free memory for the CAN message */
            if( bSuccess) {
              for(i=0;i<8;i++) *(candata_ + (*pRead)*8 + i) = message.mData[i];
              *(canmsgid_ + (*pRead)) = message.mID;
              *(canchannel_ + (*pRead)) = message.mChannel;
              BLFreeObject( hFile, &message.mHeader.mBase);
              *pRead += 1;
            }
            break;
        case BL_OBJ_TYPE_CAN_MESSAGE2:
            /* read CAN message */
            message2.mHeader.mBase = base;
            bSuccess = BLReadObjectSecure( hFile, &message2.mHeader.mBase, sizeof(message2));
            /* free memory for the CAN message */
            if( bSuccess) {
              for(i=0;i<8;i++) *(candata_ + (*pRead)*8 + i) = message2.mData[i];
              *(canmsgid_ + (*pRead)) = message2.mID;
              *(canchannel_ + (*pRead)) = message2.mChannel;
              BLFreeObject( hFile, &message2.mHeader.mBase);
              *pRead += 1;
            }
            break;
        case BL_OBJ_TYPE_ENV_INTEGER:
        case BL_OBJ_TYPE_ENV_DOUBLE:
        case BL_OBJ_TYPE_ENV_STRING:
        case BL_OBJ_TYPE_ENV_DATA:
        case BL_OBJ_TYPE_ETHERNET_FRAME:
        case BL_OBJ_TYPE_APP_TEXT:
        default:
            /* skip all other objects */
            bSuccess = BLSkipObject( hFile, &base);
            break;
        }
        //mexPrintf("%s%u\n", "count: ", *pRead);
    }

    /* close file */
    if ( !BLCloseHandle( hFile))
    {
        return -1;
    }

    return bSuccess ? 0 : -1;
}

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
    LPCTSTR pFileName = _T( "chan124_new.blf");
    DWORD dwRead;
    double *candata, *canmsgid, *canchannel, cantime;
    
    int result = 0;
    
    VBLFileStatisticsEx statistics = { sizeof( statistics)};
    result = read_statistics( pFileName, &statistics);

    // plhs[0]: candata
    plhs[0] = mxCreateDoubleMatrix (8,statistics.mObjectCount , mxREAL);
    candata = mxGetPr(plhs[0]);
    
    // plhs[1]: canmsgid
    plhs[1] = mxCreateDoubleMatrix (1,statistics.mObjectCount , mxREAL);
    canmsgid = mxGetPr(plhs[1]);
    
    // plhs[2]: canchannel
    plhs[2] = mxCreateDoubleMatrix (1,statistics.mObjectCount , mxREAL);
    canchannel = mxGetPr(plhs[2]);
    
    // plhs[3]: camtime
    //plhs[3] = mxCreateDoubleMatrix (1,statistics.mObjectCount , mxREAL);
    //cantime = mxGetPr(plhs[3]);
    
    result = read_info( pFileName, &dwRead, candata, canmsgid, canchannel);
    mxSetN(plhs[0],dwRead);
    mxSetN(plhs[1],dwRead);
    mxSetN(plhs[2],dwRead);
  
}

