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

MODULE data_struc
 ! used to define model data structures
 USE nrtype
 USE multiconst,only:integerMissing
 implicit none
 private
 ! ***********************************************************************************************************
 ! Define the model decisions
 ! ***********************************************************************************************************
 ! the model decision structure
 type,public  :: model_options
  character(len=64)                      :: cOption='notPopulatedYet'
  character(len=64)                      :: cDecision='notPopulatedYet'
  integer(i4b)                           :: iDecision=integerMissing
 end type model_options
 type(model_options),allocatable,save,public :: model_decisions(:)      ! the decision structure
 ! ***********************************************************************************************************
 ! Define metadata for model forcing datafile
 ! ***********************************************************************************************************
 ! define a derived type for the data in the file
 type,public  :: file_info
  character(len=256)                     :: filenmDesc='notPopulatedYet' ! name of file that describes the data
  character(len=256)                     :: filenmData='notPopulatedYet' ! name of data file
  integer(i4b)                           :: ncols                    ! number of columns in the file
  integer(i4b)                           :: ixFirstHRU               ! index of the first HRU to share the same data
  integer(i4b),allocatable               :: time_ix(:)               ! column index for each time variable
  integer(i4b),allocatable               :: data_ix(:)               ! column index for each forcing data variable
 end type file_info
 ! and save all the data in a single data structure
 ! NOTE: vector (HRU dimension)
 type(file_info),allocatable,save,public :: forcFileInfo(:)   ! file info for model forcing data
 ! ***********************************************************************************************************
 ! Define metadata on model parameters
 ! ***********************************************************************************************************
 ! define a data type to store model parameter information
 type,public  :: par_info
  real(dp)                               :: default_val              ! default parameter value
  real(dp)                               :: lower_limit              ! lower bound
  real(dp)                               :: upper_limit              ! upper bound
 endtype par_info
 ! define a vector, with a separate element for each parameter (variable)
 type(par_info),allocatable,save,public  :: localParFallback(:)  ! local column default parameters
 type(par_info),allocatable,save,public  :: basinParFallback(:)  ! basin-average default parameters
 ! ***********************************************************************************************************
 ! Define variable metadata
 ! ***********************************************************************************************************
 ! define derived type for model variables, including name, decription, and units
 type,public :: var_info
  character(len=64)                      :: varname=''       ! variable name
  character(len=128)                     :: vardesc=''       ! variable description
  character(len=64)                      :: varunit=''       ! variable units
  character(len=32)                      :: vartype=''       ! variable type (scalar, model layers, etc.)
  logical(lgt)                           :: v_write=.FALSE.  ! flag to write variable to the output file
 endtype var_info
 ! define arrays of metadata
 type(var_info),allocatable,save,public  :: time_meta(:)     ! model time information
 type(var_info),allocatable,save,public  :: forc_meta(:)     ! model forcing data
 type(var_info),allocatable,save,public  :: attr_meta(:)     ! local attributes
 type(var_info),allocatable,save,public  :: type_meta(:)     ! local classification of veg, soil, etc.
 type(var_info),allocatable,save,public  :: mpar_meta(:)     ! local model parameters for each HRU
 type(var_info),allocatable,save,public  :: mvar_meta(:)     ! local model variables for each HRU
 type(var_info),allocatable,save,public  :: indx_meta(:)     ! local model indices for each HRU
 type(var_info),allocatable,save,public  :: bpar_meta(:)     ! basin parameters for aggregated processes
 type(var_info),allocatable,save,public  :: bvar_meta(:)     ! basin parameters for aggregated processes
 type(var_info),allocatable,save,public  :: state_meta(:)    ! local state variables for each HRU
 type(var_info),allocatable,save,public  :: diag_meta(:)     ! local diagnostic variables for each HRU
 type(var_info),allocatable,save,public  :: flux_meta(:)     ! local model fluxes for each HRU
 type(var_info),allocatable,save,public  :: deriv_meta(:)    ! local model derivatives for each HRU
 ! ***********************************************************************************************************
 ! Define hierarchal derived data types
 ! ***********************************************************************************************************
 ! define named variables to describe the layer type
 integer(i4b),parameter,public      :: ix_soil=1001          ! named variable to denote a soil layer
 integer(i4b),parameter,public      :: ix_snow=1002          ! named variable to denote a snow layer

 ! define named variables to describe the state varible type
 integer(i4b),parameter,public      :: ixNrgState=2001       ! named variable defining the energy state variable
 integer(i4b),parameter,public      :: ixWatState=2002       ! named variable defining the total water state variable
 integer(i4b),parameter,public      :: ixMatState=2003       ! named variable defining the matric head state variable
 integer(i4b),parameter,public      :: ixMassState=2004      ! named variable defining the mass of water (currently only used for the veg canopy)

 ! define derived types to hold multivariate data for a single variable (different variables have different length)
 ! NOTE: use derived types here to facilitate adding the "variable" dimension
 ! ** double precision type
 type, public :: dlength
  real(dp),allocatable                       :: dat(:) 
 endtype dlength
 ! ** integer type
 type, public :: ilength
  integer(i4b),allocatable                   :: dat(:) 
 endtype ilength

 ! define derived types to hold data for multiple variables
 ! NOTE: use derived types here to facilitate adding extra dimensions (e.g., spatial)
 ! ** double precision type of variable length
 type, public :: var_dlength
  type(dlength),allocatable                  :: var(:) 
 endtype var_dlength
 ! ** integer type of variable length
 type, public :: var_ilength
  type(ilength),allocatable                  :: var(:) 
 endtype var_ilength
 ! ** double precision type of fixed length
 type, public :: var_d
  real(dp),allocatable                       :: var(:) 
 endtype var_d
 ! ** integer type of variable length
 type, public :: var_i
  integer(i4b),allocatable                   :: var(:) 
 endtype var_i


 ! define derived types to hold multivariate data for a single variable (different variables have different length)
 ! NOTE: use derived types here to facilitate adding the "variable" dimension
 ! ** double precision type
 !type, public :: doubleVec
 ! real(dp),allocatable        :: dat(:)
 !endtype doubleVec
 !! ** integer type
 !type, public :: intVec
 ! integer(i4b),allocatable    :: dat(:)
 !endtype intVec

 ! define derived types to hold data for multiple variables
 ! ** double precision type of variable length
 !type, public :: var_doubleVec
 ! type(doubleVec),allocatable :: var(:)
 !endtype var_doubleVec
 !! ** integer type of variable length
 !type, public :: var_intVec
 ! type(intVec),allocatable    :: var(:)
 !endtype var_intVec
 !! ** double precision type of fixed length
 !type, public :: var_double
 ! real(dp),allocatable        :: var(:)
 !endtype var_double
 !! ** integer type of variable length
 !type, public :: var_int
 ! integer(i4b),allocatable    :: var(:)
 !endtype var_int

 ! define derived types to hold spatial
 ! ** double precision type of variable length
 type, public :: spatial_doubleVec
  type(var_dlength),allocatable :: hru(:)
 endtype spatial_doubleVec
 ! ** integer type of variable length
 type, public :: spatial_intVec
  type(var_ilength),allocatable :: hru(:)
 endtype spatial_intVec
 ! ** double precision type of fixed length
 type, public :: spatial_double
  type(var_d),allocatable       :: hru(:)
 endtype spatial_double
 ! ** integer type of variable length
 type, public :: spatial_int
  type(var_i),allocatable       :: hru(:)
 endtype spatial_int









 ! define top-level derived types
 ! NOTE: either allocate directly, or use to point to higher dimensional structures
 !type(var_i),      allocatable,save,public   :: time_hru(:)    ! model time data
 !type(var_d),      allocatable,save,public   :: forc_hru(:)    ! model forcing data
 !type(var_d),      allocatable,save,public   :: attr_hru(:)    ! local attributes for each HRU
 !type(var_i),      allocatable,save,public   :: type_hru(:)    ! local classification of soil veg etc. for each HRU
 !type(var_d),      allocatable,save,public   :: mpar_hru(:)    ! model parameters
 !type(var_dlength),allocatable,save,public   :: mvar_hru(:)    ! model variables
 !type(var_ilength),allocatable,save,public   :: indx_hru(:)    ! model indices

 ! define data types for individual HRUs, and for basin-average quantities
 !type(var_i),      allocatable,save,public   :: time_data      ! model time data
 !type(var_d),      allocatable,save,public   :: forc_data      ! model forcing data
 !type(var_d),      allocatable,save,public   :: attr_data      ! local attributes
 !type(var_i),      allocatable,save,public   :: type_data      ! local classification of veg, soil, etc.
 !type(var_d),      allocatable,save,public   :: mpar_data      ! local column model parameters
 !type(var_dlength),allocatable,save,public   :: mvar_data      ! local column model variables
 !type(var_ilength),allocatable,save,public   :: indx_data      ! local column model indices
 !type(var_d),      allocatable,save,public   :: bpar_data      ! basin-average model parameters
 !type(var_dlength),allocatable,save,public   :: bvar_data      ! basin-average model variables
 !type(var_dlength),allocatable,save,public   :: state_data     ! local column state variables 
 !type(var_dlength),allocatable,save,public   :: diag_data      ! local column diagnostic variables
 !type(var_dlength),allocatable,save,public   :: flux_data      ! local column fluxes
 !type(var_dlength),allocatable,save,public   :: deriv_data     ! local column derivatives









 ! ***********************************************************************************************************
 ! Define common variables
 ! ***********************************************************************************************************
 integer(i4b),save,public                :: numtim                   ! number of time steps
 real(dp),save,public                    :: data_step                ! time step of the data
 real(dp),save,public                    :: refJulday                ! reference time in fractional julian days
 real(dp),save,public                    :: fracJulday               ! fractional julian days since the start of year
 real(dp),save,public                    :: dJulianStart             ! julian day of start time of simulation
 real(dp),save,public                    :: dJulianFinsh             ! julian day of end time of simulation
 integer(i4b),save,public                :: yearLength               ! number of days in the current year
 integer(i4b),save,public                :: urbanVegCategory=1       ! vegetation category for urban areas
 logical(lgt),save,public                :: doJacobian=.false.       ! flag to compute the Jacobian
 logical(lgt),save,public                :: globalPrintFlag=.false.  ! flag to compute the Jacobian
 ! ***********************************************************************************************************
 ! Define ancillary data structures
 ! ***********************************************************************************************************
 type(var_i),allocatable,save,public     :: refTime        ! reference time for the model simulation
 type(var_i),allocatable,save,public     :: startTime      ! start time for the model simulation
 type(var_i),allocatable,save,public     :: finshTime      ! end time for the model simulation
 ! ***********************************************************************************************************


END MODULE data_struc

