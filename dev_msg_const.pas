unit dev_msg_const;
interface
uses windows;

const
 DBT_CONFIGCHANGECANCELED    = $0019; //A request to change the current configuration (dock or undock) has been canceled.
 DBT_CONFIGCHANGED           = $0018; //The current configuration has changed, due to a dock or undock.
 DBT_CUSTOMEVENT             = $8006; //A custom event has occurred.
 DBT_DEVICEARRIVAL           = $8000; //A device or piece of media has been inserted and is now available.
 DBT_DEVICEQUERYREMOVE       = $8001; //Permission is requested to remove a device or piece of media. Any application can deny this request and cancel the removal.
 DBT_DEVICEQUERYREMOVEFAILED = $8002; //A request to remove a device or piece of media has been canceled.
 DBT_DEVICEREMOVECOMPLETE    = $8004; //A device or piece of media has been removed.
 DBT_DEVICEREMOVEPENDING     = $8003; //A device or piece of media is about to be removed. Cannot be denied.
 DBT_DEVICETYPESPECIFIC      = $8005; //A device-specific event has occurred.
 DBT_DEVNODES_CHANGED        = $0007; //A device has been added to or removed from the system.
 DBT_QUERYCHANGECONFIG       = $0017; //Permission is requested to change the current configuration (dock or undock).
 DBT_USERDEFINED             = $FFFF; //The meaning of this message is user-defined.

 DBT_DEVTYP_DEVICEINTERFACE = $00000005; //Class of devices. This structure is a DEV_BROADCAST_DEVICEINTERFACE structure.
 DBT_DEVTYP_HANDLE          = $00000006; //File system handle. This structure is a DEV_BROADCAST_HANDLE structure.
 DBT_DEVTYP_OEM             = $00000000; //OEM- or IHV-defined device type. This structure is a DEV_BROADCAST_OEM structure.
 DBT_DEVTYP_PORT            = $00000003; //Port device (serial or parallel). This structure is a DEV_BROADCAST_PORT structure.
 DBT_DEVTYP_VOLUME          = $00000002; //Logical volume. This structure is a DEV_BROADCAST_VOLUME structure.

type
 _DEV_BROADCAST_HDR=record
  dbch_size       : DWORD;
  dbch_devicetype : DWORD;
  dbch_reserved   : DWORD;
 end;

 _DEV_BROADCAST_PORT=record
  dbch_size       : DWORD;
  dbch_devicetype : DWORD;
  dbch_reserved   : DWORD;
  dbcp_name       : array [0..255]of wchar;
 end;

implementation

end.
