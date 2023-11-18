#!/bin/bash


PROJECT_ID=$1
REGION=$2
NETWORK_NAME_1=$3
NETWORK_NAME_2=$4
VPN_SHARED_SECRET=$5

################################################################################################
# Create Google Cloud Router
gcloud compute routers create "${NETWORK_NAME_1}-router" \
   --project=$PROJECT_ID \
   --region=$REGION \
   --asn=65001 \
   --network "$NETWORK_NAME_1"
# Create VPN Gateways
gcloud compute vpn-gateways create "${NETWORK_NAME_1}-gateway" \
   --project=$PROJECT_ID \
   --region=$REGION \
   --network $NETWORK_NAME_1


################################################################################################
# Create Google Cloud Router
gcloud compute routers create "${NETWORK_NAME_2}-router" \
   --project=$PROJECT_ID \
   --region=$REGION \
   --asn=65002 \
   --network "$NETWORK_NAME_2"
# Create VPN Gateways
gcloud compute vpn-gateways create "${NETWORK_NAME_2}-gateway" \
   --project=$PROJECT_ID \
   --region=$REGION \
   --network "$NETWORK_NAME_2"

################################################################################################
# Create hybrid VPN Tunnels
gcloud compute vpn-tunnels create "${NETWORK_NAME_1}-tunnel-0" \
   --project=$PROJECT_ID \
   --region=$REGION \
   --vpn-gateway "${NETWORK_NAME_1}-gateway" \
   --peer-gcp-gateway "${NETWORK_NAME_2}-gateway" \
   --router ${NETWORK_NAME_1}-router \
   --interface=0 \
   --shared-secret $VPN_SHARED_SECRET
gcloud compute vpn-tunnels create "${NETWORK_NAME_1}-tunnel-1" \
   --project=$PROJECT_ID \
   --region=$REGION \
   --vpn-gateway ${NETWORK_NAME_1}-gateway \
   --peer-gcp-gateway ${NETWORK_NAME_2}-gateway \
   --router ${NETWORK_NAME_1}-router \
   --interface=1 \
   --shared-secret $VPN_SHARED_SECRET

# Create Onprem VPN Tunnels
gcloud compute vpn-tunnels create "${NETWORK_NAME_2}-tunnel-0" \
   --project=$PROJECT_ID \
   --region=$REGION \
   --vpn-gateway ${NETWORK_NAME_2}-gateway \
   --peer-gcp-gateway ${NETWORK_NAME_1}-gateway \
   --router "${NETWORK_NAME_2}-router" \
   --interface=0 \
   --shared-secret $VPN_SHARED_SECRET
gcloud compute vpn-tunnels create "${NETWORK_NAME_2}-tunnel-1" \
   --project=$PROJECT_ID \
   --region=$REGION \
   --vpn-gateway ${NETWORK_NAME_2}-gateway \
   --peer-gcp-gateway ${NETWORK_NAME_1}-gateway \
   --router "${NETWORK_NAME_2}-router" \
   --interface=1 \
   --shared-secret $VPN_SHARED_SECRET

################################################################################################
# Router configuration, Create BGP sessions
gcloud compute routers add-interface ${NETWORK_NAME_1}-router \
    --project=$PROJECT_ID \
    --interface-name=${NETWORK_NAME_1}-to-${NETWORK_NAME_2}-0 \
    --ip-address=169.254.0.1 \
    --mask-length=30 \
    --vpn-tunnel=${NETWORK_NAME_1}-tunnel-0 \
    --region=$REGION
gcloud compute routers add-interface ${NETWORK_NAME_1}-router \
    --project=$PROJECT_ID \
    --interface-name=${NETWORK_NAME_1}-to-${NETWORK_NAME_2}-1 \
    --ip-address=169.254.1.1 \
    --mask-length=30 \
    --vpn-tunnel=${NETWORK_NAME_1}-tunnel-1 \
    --region=$REGION
gcloud compute routers add-bgp-peer ${NETWORK_NAME_1}-router \
    --project=$PROJECT_ID \
    --peer-name=${NETWORK_NAME_1}-peer-0 \
    --interface=${NETWORK_NAME_1}-to-${NETWORK_NAME_2}-0 \
    --peer-ip-address=169.254.0.2 \
    --peer-asn=65002 \
    --region=$REGION \
    --advertised-route-priority=0
gcloud compute routers add-bgp-peer ${NETWORK_NAME_1}-router \
    --project=$PROJECT_ID \
    --peer-name=${NETWORK_NAME_1}-peer-1 \
    --interface=${NETWORK_NAME_1}-to-${NETWORK_NAME_2}-1 \
    --peer-ip-address=169.254.1.2 \
    --peer-asn=65002 \
    --region=$REGION \
    --advertised-route-priority=0

# Router configuration, Create Onprem BGP sessions
gcloud compute routers add-interface ${NETWORK_NAME_2}-router \
    --project=$PROJECT_ID \
    --interface-name=${NETWORK_NAME_2}-to-${NETWORK_NAME_1}-0 \
    --ip-address=169.254.0.2 \
    --mask-length=30 \
    --vpn-tunnel=${NETWORK_NAME_2}-tunnel-0 \
    --region=$REGION
gcloud compute routers add-interface ${NETWORK_NAME_2}-router \
    --project=$PROJECT_ID \
    --interface-name=${NETWORK_NAME_2}-to-${NETWORK_NAME_1}-1 \
    --ip-address=169.254.1.2 \
    --mask-length=30 \
    --vpn-tunnel=${NETWORK_NAME_2}-tunnel-1 \
    --region=$REGION
gcloud compute routers add-bgp-peer ${NETWORK_NAME_2}-router \
    --project=$PROJECT_ID \
    --peer-name=${NETWORK_NAME_2}-peer-0 \
    --interface=${NETWORK_NAME_2}-to-${NETWORK_NAME_1}-0 \
    --peer-ip-address=169.254.0.1 \
    --peer-asn=65001 \
    --region=$REGION \
    --advertised-route-priority=0
gcloud compute routers add-bgp-peer ${NETWORK_NAME_2}-router \
    --project=$PROJECT_ID \
    --peer-name=${NETWORK_NAME_2}-peer-1 \
    --interface=${NETWORK_NAME_2}-to-${NETWORK_NAME_1}-1 \
    --peer-ip-address=169.254.1.1 \
    --peer-asn=65001 \
    --region=$REGION \
    --advertised-route-priority=0