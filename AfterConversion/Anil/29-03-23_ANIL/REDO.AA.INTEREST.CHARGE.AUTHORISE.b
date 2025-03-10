* @ValidationCode : MjotMjA4NDUxMzk1ODpDcDEyNTI6MTY4MDA2NDgyMDgzNDpJVFNTOi0xOi0xOjA6MDpmYWxzZTpOL0E6UjIxX0FNUi4wOi0xOi0x
* @ValidationInfo : Timestamp         : 29 Mar 2023 10:10:20
* @ValidationInfo : Encoding          : Cp1252
* @ValidationInfo : User Name         : ITSS
* @ValidationInfo : Nb tests success  : N/A
* @ValidationInfo : Nb tests failure  : N/A
* @ValidationInfo : Rating            : N/A
* @ValidationInfo : Coverage          : N/A
* @ValidationInfo : Strict flag       : N/A
* @ValidationInfo : Bypass GateKeeper : false
* @ValidationInfo : Compiler Version  : R21_AMR.0
* @ValidationInfo : Copyright Temenos Headquarters SA 1993-2021. All rights reserved.
$PACKAGE APAP.AA
SUBROUTINE REDO.AA.INTEREST.CHARGE.AUTHORISE
*-----------------------------------------------------------------------------
*DESCRIPTION:
*------------
*This routine is used to define fields that will update NCF table based on Interest paid.
*------------------------------------------------------------------------------------------
* Input/Output:
*--------------
* IN  : -NA-
* OUT : -NA-
*
* Dependencies:
*---------------
* CALLS : -NA-
* CALLED BY : -NA-
*
* Revision History:
*------------------
*   Date               who           Reference                                    Description
* 14-dec-2011          Prabhu.N     PACS00167681 and PACS00167681                 Initial Creation
* Date                 who                   Reference              
* 29-03-2023          CONVERSTION TOOL   R22 AUTO CONVERSTION VM TO @VM AND FM TO @FM
* 29-03-2023          ANIL KUMAR B       R22 MANUAL CONVERSTION -NO CHANGES
*-----------------------------------------------------------------------------
    $INSERT I_COMMON
    $INSERT I_EQUATE
    $INSERT I_F.ACCOUNT
    $INSERT I_F.REDO.AA.INTEREST.CHARGE
    $INSERT I_F.REDO.NCF.ISSUED
    $INSERT I_F.REDO.L.NCF.UNMAPPED
    $INSERT I_F.REDO.L.NCF.STOCK

    GOSUB INITIALISE
    GOSUB PROCESS

RETURN
PROCESS:


    Y.DATE=R.NEW(REDO.IC.DATE)
    Y.ACCOUNT.ID=ID.NEW

    CALL F.READ(FN.ACCOUNT,Y.ACCOUNT.ID,R.ACC,F.ACCOUNT,ERR)
    Y.CURRENCY=R.ACC<AC.CURRENCY>

    FN.REDO.L.NCF.STOCK='F.REDO.L.NCF.STOCK'

    CALL CACHE.READ(FN.REDO.L.NCF.STOCK,'SYSTEM',R.REDO.L.NCF.STOCK,ERR)

    FN.REDO.NCF.ISSUED='F.REDO.NCF.ISSUED'
    F.REDO.NCF.ISSUED =''
    CALL OPF(FN.REDO.NCF.ISSUED,F.REDO.NCF.ISSUED)

    Y.TOT.CHG.LIST=R.REDO.L.NCF.STOCK<ST.AA.IC.TYPE>
    CHANGE @VM TO @FM IN Y.TOT.CHG.LIST
    Y.CHG.CNT=1
    Y.CHG.CNT.TOT=DCOUNT(Y.TOT.CHG.LIST,@FM)
    LOOP
    WHILE Y.CHG.CNT LE Y.CHG.CNT.TOT
        Y.BALANCE.TYPE=Y.TOT.CHG.LIST<Y.CHG.CNT>
        CALL AA.GET.ECB.BALANCE.AMOUNT(Y.ACCOUNT.ID, Y.BALANCE.TYPE, Y.DATE, Y.BALANCE.AMOUNT,Y.RET.ERROR)
        Y.TOT.CHARGE.AMT+=Y.BALANCE.AMOUNT
        Y.CHG.CNT += 1
    REPEAT

    Y.FT.CHARGE.AMT =Y.TOT.CHARGE.AMT-Y.TOTAL.CHG.INT.PREV
    Y.FT.CHARGE.AMT =Y.CURRENCY :' ':Y.FT.CHARGE.AMT

    CALL F.READ(FN.REDO.NCF.ISSUED,Y.NCF.ID,R.REDO.NCF.ISSUED,F.REDO.NCF.ISSUED,ERR)
    CALL F.READ(FN.REDO.NCF.UNMAPPED,Y.NCF.ID,R.REDO.NCF.UNMAPPED,F.REDO.NCF.UNMAPPED,ERR)

    Y.NCF.LIST=R.REDO.NCF.ISSUED<ST.IS.NCF>
    Y.NCF.LIST.CNT=DCOUNT(Y.NCF.LIST,@VM)
    Y.TAX.AMOUNT=R.REDO.NCF.ISSUED<ST.IS.TAX.AMOUNT>

    IF Y.TAX.AMOUNT AND Y.NCF.LIST.CNT EQ 1 AND Y.FT.CHARGE.AMT THEN
        CALL REDO.ASSIGN.NCF(Y.NCF.ID,Y.FT.CHARGE.AMT)
        RETURN
    END

    IF NOT(Y.TAX.AMOUNT) AND NOT(Y.NCF.LIST.CNT) AND Y.FT.CHARGE.AMT AND NOT(R.REDO.NCF.UNMAPPED) THEN
        CALL REDO.ASSIGN.NCF(Y.NCF.ID,Y.FT.CHARGE.AMT)
        RETURN
    END

    IF NOT(R.REDO.NCF.ISSUED) THEN
        GOSUB UNMAP.PROCESS
    END
    ELSE
        IF R.REDO.NCF.ISSUED<ST.IS.CHARGE.AMOUNT> ELSE
            R.REDO.NCF.ISSUED<ST.IS.CHARGE.AMOUNT>=Y.FT.CHARGE.AMT
            CALL F.WRITE(FN.REDO.NCF.ISSUED,Y.NCF.ID,R.REDO.NCF.ISSUED)
        END
    END
RETURN
INITIALISE:

    FN.REDO.NCF.ISSUED ='F.REDO.NCF.ISSUED'
    F.REDO.NCF.ISSUED=''
    CALL OPF(FN.REDO.NCF.ISSUED,F.REDO.NCF.ISSUED)

    FN.REDO.NCF.UNMAPPED='F.REDO.L.NCF.UNMAPPED'
    F.REDO.NCF.UNMAPPED=''
    CALL OPF(FN.REDO.NCF.UNMAPPED,F.REDO.NCF.UNMAPPED)

    FN.ACCOUNT='F.ACCOUNT'
    F.ACCOUNT=''
    CALL OPF(FN.ACCOUNT,F.ACCOUNT)

    Y.NCF.OLD.DATE=R.OLD(REDO.IC.DATE)
    Y.NCF.DATE=R.NEW(REDO.IC.DATE)
    Y.NCF.ID  =R.NEW(REDO.IC.NCF.ID)
    Y.TOTAL.CHG.INT.PREV =R.NEW(REDO.IC.TOTAL.INT.BEF)

RETURN
UNMAP.PROCESS:
    IF R.REDO.NCF.UNMAPPED THEN
        IF R.REDO.NCF.UNMAPPED<ST.UN.CHARGE.AMOUNT> ELSE
            R.REDO.NCF.UNMAPPED<ST.UN.CHARGE.AMOUNT>=Y.FT.CHARGE.AMT
            CALL F.WRITE(FN.REDO.NCF.UNMAPPED,Y.NCF.ID,R.REDO.NCF.UNMAPPED)
        END
    END
RETURN
END
