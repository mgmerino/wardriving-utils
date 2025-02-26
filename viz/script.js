var map = L.map("map").setView([40.416775, -3.70379], 12); // Madrid por defecto

L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
  attribution: "© OpenStreetMap contributors",
}).addTo(map);

fetch("./maps/mymap.json")
  .then((response) => response.json())
  .then((data) => {
    L.geoJSON(data, {
      onEachFeature: function (feature, layer) {
        layer.bindPopup(`
                  <b>SSID:</b> ${feature.properties.ssid}<br>
                  <b>Mac address:</b> ${feature.properties.mac_address}<br>
                  <b>Sec. level:</b> ${feature.properties.security}<br>
                  <b>Channel:</b> ${feature.properties.channel}<br>
                  <b>RSSI:</b> ${feature.properties.rssi} dBm<br>
                  <b>Timestamp:</b> ${feature.properties.timestamp}
              `);
      },
    }).addTo(map);
  })
  .catch((error) => console.error("Error cargando GeoJSON:", error));
