config system admin
edit ${user}
set password ${pass}
set accprofile super_admin
end
config system global
set alias ${hostname}
set allow-traffic-redirect disable
set hostname ${hostname}
set ipv6-allow-traffic-redirect disable
set timezone 04
end
config system accprofile
edit "api"
set secfabgrp read-write
set ftviewgrp read-write
set authgrp read-write
set sysgrp read-write
set netgrp read-write
set loggrp read-write
set fwgrp read-write
set vpngrp read-write
set utmgrp read-write
set wanoptgrp read-write
set wifi read-write
next
end
config system geneve
edit "gwlbe-gen"
set interface "port2"
set type ppp
set remote-ip ${gwlb_ip}
next
end
config system interface
edit "gwlbe-gen"
set vdom "root"
set vrf 2
set type geneve
set snmp-index 8
set interface "port2"
next
edit "port1"
set vdom "root"
set vrf 1
set mode dhcp
set allowaccess ping https ssh http fgfm
set type physical
set snmp-index 1
set mtu-override enable
set mtu 9001
next
edit "port2"
set vdom "root"
set vrf 2
set mode dhcp
set allowaccess https http probe-response
set type physical
set snmp-index 2
set defaultgw disable
set mtu-override enable
set mtu 9001
next
end
config system api-user
edit "api-admin"
set api-key ENC SH2KG/ZD9yUHkemXhLydqeZ6fgzNX7UXZ2x8n53S6fUtWLKxo2T3BaE79ky37g=
set accprofile "api"
set vdom "root"
next
end
config system probe-response
set port 8008
set http-probe-value "OK"
set mode http-probe
end
config firewall policy
edit 1
set name "Main"
set srcintf "gwlbe-gen"
set dstintf "gwlbe-gen"
set action accept
set srcaddr "all"
set dstaddr "all"
set schedule "always"
set service "HTTPS" "HTTP" "ALL_ICMP"
set utm-status enable
set logtraffic all
next
end
config router static
edit 1
set dst ${gwlb_ip} ${gwlb_subnet_mask_decimal}
set gateway ${inspection_first_usable_ip}
set device "port2"
next
edit 2
set device "gwlbe-gen"
next
end
config router policy
edit 1
set input-device "gwlbe-gen"
set src "0.0.0.0/0.0.0.0"
set dst "0.0.0.0/0.0.0.0"
set output-device "gwlbe-gen"
next
end