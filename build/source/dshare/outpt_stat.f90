! SUMMA - Structure for Unifying Multiple Modeling Alternatives
! Copyright (C) 2014-2015 NCAR/RAL
!
! This file is part of SUMMA
!
! For more information see: http://www.ral.ucar.edu/projects/summa
!
! This program is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.

! used to manage output statistics of the model and forcing variables
module output_stats
USE nrtype
implicit none
private
public :: calcStats
!public :: compileBasinStats
contains

 ! ******************************************************************************************************
 ! public subroutine calcStats is called at every model timestep to update/store output statistics 
 ! from model variables
 ! ******************************************************************************************************
 subroutine calcStats(stat,dat,meta,iStep,err,message)
 USE nrtype
 USE data_types,only:extended_info,dlength,ilength  ! metadata structure type
 USE var_lookup,only:iLookVarType                   ! named variables for variable types 
 USE var_lookup,only:iLookStat                      ! named variables for output statistics types 
 implicit none

 ! dummy variables
 type(dlength) ,intent(inout)   :: stat(:)          ! statistics
 class(*)      ,intent(in)      :: dat(:)           ! data
 type(extended_info),intent(in) :: meta(:)          ! metadata
 integer(i4b)  ,intent(in)      :: iStep            ! timestep index to compare with oFreq of each variable
 integer(i4b)  ,intent(out)     :: err              ! error code
 character(*)  ,intent(out)     :: message          ! error message

 ! internals
 character(256)                 :: cmessage         ! error message
 integer(i4b)                   :: iVar             ! index for varaiable loop
 integer(i4b)                   :: pVar             ! index into parent structure
 real(dp)                       :: tdata            ! dummy for pulling info from dat structure

 ! initialize error control
 err=0; message='calcStats/'

 do iVar = 1,size(meta)                             ! model variables

  ! don't do anything if var is not requested
  if (meta(iVar)%outFreq<0) cycle
  
  ! only treat stats of scalars - all others handled separately
  if (meta(iVar)%varType==iLookVarType%outstat) then

   ! index into parent structure
   pVar = meta(iVar)%ixParent

   select type (dat)
    type is (real(dp)); tdata = dat(pVar)
    type is (dlength) ; tdata = dat(pVar)%dat(1)
    type is (ilength) ; tdata = real(dat(pVar)%dat(1), kind(dp))
    class default;err=20;message=trim(message)//'dat type not found';return
   end select

   ! claculate statistics
   if (trim(meta(iVar)%varName)=='time') then
    stat(iVar)%dat(iLookStat%inst) = tdata
   else
    call calc_stats(meta(iVar),stat(iVar),tdata,iStep,err,cmessage)  
   end if

   if(err/=0)then; message=trim(message)//trim(cmessage);return; end if  
  end if
 end do                                             ! model variables

 return
 end subroutine calcStats


 ! ***********************************************************************************
 ! Private subroutine calc_stats is a generic fucntion to deal with any variable type.
 ! Called from compile_stats 
 ! ***********************************************************************************
 subroutine calc_stats(meta,stat,tdata,iStep,err,message)
 USE nrtype
 ! data structures
 USE data_types,only:var_info,ilength,dlength ! type dec for meta data structures 
 USE var_lookup,only:maxVarStat       ! # of output statistics 
 USE globalData,only:outFreq          ! output frequencies 
 ! global variables 
 USE globalData,only:data_step        ! forcing timestep
 ! structures of named variables
 USE var_lookup,only:iLookVarType     ! named variables for variable types 
 USE var_lookup,only:iLookStat        ! named variables for output statistics types 
 implicit none
 ! dummy variables
 class(var_info),intent(in)        :: meta        ! meta dat a structure
 class(*)       ,intent(inout)     :: stat        ! statistics structure
 real(dp)       ,intent(in)        :: tdata       ! data structure
 integer(i4b)   ,intent(in)        :: iStep       ! timestep
 integer(i4b)   ,intent(out)       :: err         ! error code
 character(*)   ,intent(out)       :: message     ! error message
 ! internals
 real(dp),dimension(maxvarStat+1)  :: tstat       ! temporary stats vector
 integer(i4b)                      :: iStat       ! statistics loop
 integer(i4b)                      :: iFreq       ! statistics loop
 ! initialize error control
 err=0; message='calc_stats/'

 ! pull current frequency for normalization
 iFreq = meta%outFreq
 if (iFreq<0) then; err=-20; message=trim(message)//'bad output file id# (outfreq)'; return; end if

 ! pack back into struc
 select type (stat)
  type is (ilength); tstat = real(stat%dat)
  type is (dlength); tstat = stat%dat
  class default;err=20;message=trim(message)//'stat type not found';return
 end select

 ! ---------------------------------------------
 ! reset statistics at new frequency period 
 ! ---------------------------------------------
 if ((mod(iStep,outFreq(iFreq))==1).or.(outFreq(iFreq)==1)) then
  do iStat = 1,maxVarStat                          ! loop through output statistics
   if (.not.meta%statFlag(iStat)) cycle            ! don't bother if output flag is off
   if (meta%varType.ne.iLookVarType%outstat) cycle ! only calculate stats for scalars 
   select case(iStat)                              ! act depending on the statistic 
    case (iLookStat%totl)                          ! summation over period
     tstat(iStat) = 0                              ! resets stat at beginning of period
    case (iLookStat%mean)                          ! mean over period
     tstat(iStat) = 0. 
    case (iLookStat%vari)                          ! variance over period
     tstat(iStat) = 0                              ! resets E[X^2] term in var calc
     tstat(maxVarStat+1) = 0                       ! resets E[X]^2 term  
    case (iLookStat%mini)                          ! minimum over period
     tstat(iStat) = huge(tstat(iStat))             ! resets stat at beginning of period
    case (iLookStat%maxi)                          ! maximum over period
     tstat(iStat) = -huge(tstat(iStat))            ! resets stat at beginning of period
    case (iLookStat%mode)                          ! mode over period (does not work)
     tstat(iStat) = -9999.
   end select
  end do ! iStat 
 end if

 ! ---------------------------------------------
 ! Calculate each statistic that is requested by user
 ! ---------------------------------------------
 do iStat = 1,maxVarStat                           ! loop through output statistics
  if (.not.meta%statFlag(iStat)) cycle             ! do not bother if output flag is off
  if (meta%varType.ne.iLookVarType%outstat) cycle  ! only calculate stats for scalars 
  select case(iStat)                               ! act depending on the statistic 
   case (iLookStat%totl)                           ! summation over period
    tstat(iStat) = tstat(iStat) + tdata            ! into summation
   case (iLookStat%inst)                           ! instantaneous
    tstat(iStat) = tdata                                        
   case (iLookStat%mean)                           ! mean over period
    tstat(iStat) = tstat(iStat) + tdata            ! adds timestep to sum 
   case (iLookStat%vari)                           ! variance over period
    tstat(iStat) = tstat(iStat) + tdata**2         ! sum into E[X^2] term
    tstat(maxVarStat+1) = tstat(maxVarStat+1) + tdata  ! sum into E[X]^2 term        
   case (iLookStat%mini)                           ! minimum over period
    if (tdata.le.tstat(iStat)) tstat(iStat) = tdata! overwrites minimum iff 
   case (iLookStat%maxi)                           ! maximum over period
    if (tdata.ge.tstat(iStat)) tstat(iStat) = tdata! overwrites maximum iff 
   case (iLookStat%mode)                           ! (does not work)
    tstat(iStat) = -9999. 
  end select
 end do ! iStat 

 ! ---------------------------------------------
 ! finalize statistics at end of frequenncy period 
 ! ---------------------------------------------
 if (mod(iStep,outFreq(iFreq))==0) then
  do iStat = 1,maxVarStat                          ! loop through output statistics
   if (.not.meta%statFlag(iStat)) cycle            ! do not bother if output flag is off
   if (meta%vartype.ne.iLookVarType%outstat) cycle ! only calculate stats for scalars 
   select case(iStat)                              ! act depending on the statistic 
    case (iLookStat%totl)                          ! summation over period
     tstat(iStat) = tstat(iStat)*data_step         ! scale by seconds per timestep
    case (iLookStat%mean)                          ! mean over period
     tstat(iStat) = tstat(iStat)/outFreq(iFreq)    ! normalize sum into mean
    case (iLookStat%vari)                          ! variance over period
     tstat(maxVarStat+1) = tstat(maxVarStat+1)/outFreq(iFreq) ! E[X] term
     tstat(iStat) = tstat(iStat)/outFreq(iFreq) - tstat(maxVarStat+1)**2 ! full variance
   end select
  end do ! iStat 
 end if

 ! pack back into struc
 select type (stat)
  type is (ilength); stat%dat = int(tstat)
  type is (dlength); stat%dat = tstat
  class default;err=20;message=trim(message)//'stat type not found';return
 end select

 return
 end subroutine calc_stats

end module output_stats
