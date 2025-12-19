const icons = {
  open: createIcon("blue"),
  wep: createIcon("red"),
  wpa: createIcon("orange"),
  wpa2: createIcon("yellow"),
  wpa3: createIcon("green"),
  default: createIcon("gray"),
};

const securityLevels = ["open", "wep", "wpa", "wpa2", "wpa3"];

var wifiLayer;
var wifiData = [];
var markers = {};
var map = L.map("map").setView([40.416775, -3.70379], 12);
var filePath = "path/to/file.json";

L.tileLayer("https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png", {
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
  subdomains: "abcd",
  maxZoom: 20,
}).addTo(map);

function createIcon(color) {
  return L.icon({
    iconUrl: `img/${color}_pog.svg`,
    iconSize: [16, 16],
    iconAnchor: [12, 12],
    popupAnchor: [1, -34],
  });
}

function getIcon(security) {
  securityString = security.toLowerCase();

  let detectedLevels = securityLevels.filter((level) =>
    securityString.includes(level),
  );
  let bestMatch = detectedLevels.length > 0 ? detectedLevels.pop() : "default";

  return icons[bestMatch] || icons.default;
}

function loadWifiData() {
  fetch(`${filePath}`)
    .then((response) => response.json())
    .then((data) => {
      wifiData = data.features;
      updateMap();
      updateTable();
    })
    .catch((error) => console.error("Error loading data:", error));
}

function updateTable() {
  let tbody = document.querySelector("#wifi-table tbody");
  tbody.innerHTML = "";

  wifiData.forEach((feature, index) => {
    let row = tbody.insertRow();
    row.insertCell().textContent = feature.properties.ssid;
    row.insertCell().textContent = feature.properties.security;
    row.insertCell().textContent = feature.properties.rssi + " dBm";
    row.insertCell().textContent = feature.properties.channel;
    row.insertCell().textContent = feature.properties.mac_address;
    row.insertCell().textContent = feature.properties.timestamp;
    
    row.style.cursor = "pointer";
    row.addEventListener("click", () => focusNetwork(index));
  });
}

function focusNetwork(index) {
  const feature = wifiData[index];
  if (!feature) return;
  
  const coords = feature.geometry.coordinates;
  const latlng = L.latLng(coords[1], coords[0]);
  
  map.setView(latlng, 18);
  
  if (markers[index]) {
    markers[index].openPopup();
  }
  
  // Highlight active row
  document.querySelectorAll("#wifi-table tbody tr").forEach((row, i) => {
    row.classList.toggle("active", i === index);
  });
}

function updateMap() {
  if (wifiLayer) {
    map.removeLayer(wifiLayer);
  }
  
  markers = {};

  var ssidFilter = document.getElementById("ssid-filter").value.toLowerCase();
  var rssiFilter = parseInt(document.getElementById("rssi-filter").value);

  var filteredData = wifiData.filter((feature) => {
    var ssid = feature.properties.ssid.toLowerCase();
    var rssi = feature.properties.rssi;

    var matchSSID = ssidFilter === "" || ssid.includes(ssidFilter);
    var matchRSSI = isNaN(rssiFilter) || rssi > rssiFilter;

    return matchSSID && matchRSSI;
  });

  wifiLayer = L.geoJSON(filteredData, {
    pointToLayer: function (feature, latlng) {
      const index = wifiData.indexOf(feature);
      const marker = L.marker(latlng, { icon: getIcon(feature.properties.security) });
      markers[index] = marker;
      return marker;
    },
    onEachFeature: function (feature, layer) {
      layer.bindPopup(`
        <b>SSID:</b> ${feature.properties.ssid}<br>
        <b>Security:</b> ${feature.properties.security}<br>
        <b>RSSI:</b> ${feature.properties.rssi}<br>
        <b>Channel:</b> ${feature.properties.channel}<br>
        <b>MAC:</b> ${feature.properties.mac_address}<br>
        <b>Time:</b> ${feature.properties.timestamp}<br>
        `);
    },
  });
  wifiLayer.addTo(map);
}

document.getElementById("rssi-filter").addEventListener("input", function () {
  document.getElementById("rssi-value").textContent = this.value + " dBm";
});
document.getElementById("rssi-filter").addEventListener("change", function () {
  document.getElementById("rssi-value").value = this.value;
  updateMap();
  updateTable();
});

document.getElementById("apply-filters").addEventListener("click", updateMap);

loadWifiData();
