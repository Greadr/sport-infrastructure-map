document.getElementById('map').style.cursor = 'pointer'

var map = new L.Map('map',{
center: [55.690223, 37.595290],
zoom: 10,
})

map.getPane('overlayPane').style.zIndex=1000
map.zoomControl.setPosition('topleft');

var houseUnom = null
var houseAddress = null


var accessToken = 'pk.eyJ1IjoiZ3JlYWRyIiwiYSI6ImNqam9iNmlsZzBxMDQzcG5sczM4aTZjN3gifQ.t-OlIK5Oo1UEJXKOQh0J0Q';
var mapboxLightLayer = L.tileLayer(
	'https://api.mapbox.com/styles/v1/greadr/cjzl2i8sq04311cpj3uh34k2q/tiles/{z}/{x}/{y}?access_token=' + accessToken, {
	tileSize: 512,
	zoomOffset: -1,
	attribution: '© <a href="https://apps.mapbox.com/feedback/">Mapbox</a> © <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
})

// var mapboxLightLabels = L.tileLayer(
// 	'https://api.mapbox.com/styles/v1/greadr/ckbq8obzp52d41imdyckwhzhh/tiles/{z}/{x}/{y}?access_token='+ accessToken, {
// 	tileSize: 512,
// 	zoomOffset: -1,
// 	attribution: '© <a href="https://apps.mapbox.com/feedback/">Mapbox</a> © <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
// 	pane: 'overlayPane'
// })

var mapboxDarkLayer = L.tileLayer(
	'https://api.mapbox.com/styles/v1/greadr/cjtr8vj2s2qqn1fogdrvju1az/tiles/{z}/{x}/{y}?access_token=' + accessToken, {
		tileSize: 512,
		zoomOffset: -1,
		detectRetina: true,
		attribution: '© <a href="https://apps.mapbox.com/feedback/">Mapbox</a> © <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
	}).addTo(map)

osmUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
osmAttribution =
'Map data <a target="_blank" href="https://www.openstreetmap.org">OpenStreetMap.org</a> contributors, ' +
'<a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>';
osmLayer = new L.TileLayer(osmUrl, {
	attribution: osmAttribution
})

twogisUrl = 'https://tile2.maps.2gis.com/tiles?x={x}&y={y}&z={z}&v=1.1';
twogisLayer = new L.TileLayer(twogisUrl, {
});

var wmsLayers = {}
var dict_layer_names = {}
var workLayers = L.layerGroup();
for (var layer of layers) {
	var layer_pk = layer.pk
	var layer_name = layer.fields.name
	var layer_display_name = layer.fields.display_name
	var layer_style = layer.fields.style
	var layer_min_zoom = layer.fields.min_zoom
	var layer_max_zoom = layer.fields.max_zoom
	var layer_search_view = layer.fields.search_view
	dict_layer_names[layer_name] = layer_display_name
	if (layer_name) {
		map.createPane(layer_name).style.zIndex = (10-layer.fields.ordering)*100
		wmsLayers[layer_display_name] = L.tileLayer.betterWms ('https://geoserver.bigdatamap.keenetic.pro/geoserver/BigDataMap/wms', {
			layers:'BigDataMap:'+layer_name,
			styles:layer_style,
			format: 'image/png',
			transparent: 'true',
			tileSize: 512,
			pane: layer_name,
			detectRetina: true,
			pk: layer_pk,
		})
		if (layer_search_view) {
			wmsLayers[layer_display_name].options.searchView = layer_search_view
		}
		if (layer_min_zoom) {
			wmsLayers[layer_display_name].options.minZoom = layer_min_zoom
		}
		if (layer_max_zoom) {
			wmsLayers[layer_display_name].options.maxZoom = layer_min_zoom
		}

		workLayers.addLayer(wmsLayers[layer_display_name])
	}
}
wmsLayers[Object.keys(wmsLayers)[0]].addTo(map)
var baseMaps = {
	'2GIS': twogisLayer,
	"OpenStreetMap": osmLayer,
	'Mapbox Light': mapboxLightLayer,
	// 'Mapbox Labels': mapboxLightLabels,
	'Mapbox Dark': mapboxDarkLayer,
	};



var groupedOverlays = {
	"Территориальные единицы": wmsLayers
  };

var options = {
	exclusiveGroups: ["Территориальные единицы"],
	collapsed: false, 
	position: 'topleft'
};
  
layersControl = L.control.groupedLayers(null, groupedOverlays, options);
// var overlayMaps = wmsLayers;
// layersControl = new L.Control.Layers(baseMaps, overlayMaps, {collapsed: false, position: 'topleft'})
map.addControl(layersControl);


$('.openbtn').detach().insertBefore('.leaflet-control-layers');

// var themeSwitch = L.control({position: 'topleft'});
// themeSwitch.onAdd = function (map) {
// 	var div = L.DomUtil.create('div', 'themeSwitch')
// 		div.innerHTML +=
// 		'<label for="switch"><div class="toggle"></div><div class="names"><p class="light">Light</p><p class="dark">Dark</p></div></label>'
// 		return div;
// 	};
// themeSwitch.addTo(map)

// map.on('overlayadd', function(e) {
//     document.getElementsByClassName(`${e.layer.options.layers.split(':')[1]} legend`)[0].style.display = 'block'
// 	});
// map.on('overlayremove', function(e) {
// 	document.getElementsByClassName(`${e.layer.options.layers.split(':')[1]} legend`)[0].style.display = 'none'
// 	});

var legend = L.control({style:'background:white', position: 'bottomleft'});
legend.onAdd = function (map) {
var div = L.DomUtil.create('div', 'info-legend')
	div.innerHTML +=
	'<strong style="margin-bottom: -20px; display: block;"> Условные обозначения </strong><br>'
	for (var layer of layers) {
		var layer_is_legend = layer.fields.is_legend
		if (layer_is_legend) {
			var layer_name = layer.fields.name;
			if (layer_name == null)
			{
				layer_name = layers[0].fields.name
			}
			var layer_display_name = layer.fields.display_name;
			var layer_style = layer.fields.style;
			var layer_legend_name = layer.fields.legend_name;
			var layer_legend_descr = layer.fields.legend_descr;
			content = `<div class="${layer_name} legend">`;
			if (layer_legend_name) {
				content += `<b>${layer_legend_name}</b><br>`;
			}
			if (layer_legend_descr) {
				content += `<i>${layer_legend_descr}</i><br>`
			}
			
			content += `<img src="https://geoserver.bigdatamap.keenetic.pro/geoserver/wms?REQUEST=GetLegendGraphic&VERSION=1.0.0&WIDTH=30&FORMAT=image/png&LAYER=BigDataMap:${layer_name}&STYLE=${layer_style}&legend_options=fontName:Roboto;fontAntiAliasing:true;fontSize:12;dpi:91;bgColor:0x1c2233;fontColor:0xf7f8fa"></div>`;	
			div.innerHTML += content 
		}
		}
return div;
};
legend.addTo(map);


// L.Control.Watermark = L.Control.extend({
// 	onAdd: function(map) {
// 		var img = L.DomUtil.create('img');

// 		img.src = '/static/BigGeoData_transp.png';
// 		img.style.width = '100px';

// 		return img;
// 	},

// 	onRemove: function(map) {
// 		// Nothing to do here
// 	}
// });

// L.control.watermark = function(opts) {
// 	return new L.Control.Watermark(opts);
// }

// L.control.watermark({ position: 'bottomleft' }).addTo(map);



openBtn = document.getElementById("openbtn")

function closeInfo() {
	// openBtn.style.marginRight = '10px';
	sidebar.style.marginRight = "-400px";
	searchForm.value = ''
	search_form.style.marginRight = "0px";
	if (selectedObj) {
		map.removeLayer(selectedObj)
	}
}

closeBtns = document.getElementsByClassName("closebtn")
closeBtns[0].onclick = function () {
	// openBtn.style.marginRight = '10px';
	searchForm.value = ''
	search_form.style.marginRight = "0px";
	sidebarDescr.style.marginRight = "-400px";
	
}
closeBtns[1].onclick = function () {
	closeInfo()
}


function renderData (attributes, data, layerPk) {
	title.textContent = 'Информация об объекте'
	ul_sidebar.innerHTML = '';
	for (var obj in attributes) {
		for (var key in data) {
			if ((attributes[obj].fields.source_name == key) && (attributes[obj].fields.layer == layerPk)) {
				attributes[obj].fields.value = data[key];
				renderAttribute (attributes[obj].fields, ul_sidebar);
			};
		};
}

function renderAttribute(element, ul_sidebar) {
	var li = document.createElement('li');
	li.setAttribute('class','item');
	li.setAttribute('id',element.source_name);
	li.innerHTML="<b>" + element.display_name + ":</b> " + element.value;
	ul_sidebar.appendChild(li);
}
}

var selectedObj

function objInfo(e, processType) {
	var data = (e.features[0].properties);
	var objLayerName = e.features[0].id.split('.')[0]
	var currentTopLayer = Object.keys(workLayers._layers).filter(x => Object.keys(map._layers).includes(x))[0]
	var topLayerName = map._layers[currentTopLayer].options.pane;
	if (processType == 'search') {
		var objLayerName = topLayerName
	}
	var layerPk = map._layers[currentTopLayer].options.pk;
	
	
	if (objLayerName==topLayerName) {
		var selectedStyle = {
			"color": "#fff707",
			"opacity": 1,
			'fillOpacity':0,
			'weight':2,
		};
		if (selectedObj) {
			map.removeLayer(selectedObj)
		}
		selectedObj = L.geoJSON(e.features[0], {style: selectedStyle}).addTo(map);

		renderData (attributes, data, layerPk);
		// openBtn.style.marginRight = "-400px";
		search_form.style.marginRight = "-400px";
		sidebar.style.marginRight = '10px';
		// sidebar.style.marginRight  = '';
		
		// var feat = e.features[0];
		// var objCoords = turf.centroid(feat).geometry.coordinates
		// var offsetHoriz = document.getElementById('mySidebar1').clientWidth*0.005/1000;
		// map.flyToBounds([objCoords[1],objCoords[0]+offsetHoriz], 17, {
		// 		animate: true,
		// });
	}
}

// attributes = attributes.sort((a, b) => parseFloat(a.pk) - parseFloat(b.pk));

var searchForm = document.getElementsByClassName('search-text')[0];
searchForm.onsubmit = function(){
    console.log(searchForm.value)
};

function searchAlert() {
	$(".search-alert").css({'marginRight':'0px'});
	setTimeout(function(){
		$(".search-alert").css({'marginRight':'-400px'});
	}, 3000);
}

var wfs_baseurl = 'https://geoserver.bigdatamap.keenetic.pro/geoserver/wfs'

function searchFeature() {
	event.preventDefault();
	var currentTopLayer = Object.keys(workLayers._layers).filter(x => Object.keys(map._layers).includes(x))[0]
	var layer_searchview = 'odd_megasearch'
	params = {
	  service: 'wfs',
	  version: '1.1.0',
	  request: 'GetFeature',
	  typename: 'BigDataMap:'+layer_searchview,
	  viewparams: 'name:'+$(".search-text").val(),
	  outputFormat: 'text/javascript',
	  };
	
	var url = wfs_baseurl + L.Util.getParamString(params, wfs_baseurl, true)
	var callbackName = "myJSONPCallback" + Date.now() + Math.floor(Math.random() * 100000);
	$.ajax({
	url: url+"&format_options=callback:" + callbackName,
	crossDomain: true,
	dataType: 'jsonp',
	jsonp: false,
	jsonpCallback: callbackName,
	success: function (data, status, xhr) {
	  var err = typeof data === 'string' ? null : data;
	  if (typeof data==='object') {
	  if (data.features.length > 0) {
			  new_layer = data.features[0].properties.layer
			  if (map._layers[currentTopLayer].options.pane!=new_layer){
			  map._layers[currentTopLayer].removeFrom(map);
			  wmsLayers[dict_layer_names[new_layer]].addTo(map)}
		
		objInfo(data, 'search')
	  }
	  else {
		searchAlert();
	  }
	  }
	},
	error: function (xhr, status, error) {
	  console.log(error); 
	  searchAlert(); 
	}
	})
	
  }

L.Control.Styling = L.Control.extend(
{
	options:
	{
		position: 'topleft',
	},
	
	initialize: function (styles, options) {
		var i, j;
		L.Util.setOptions(this, options);
	
		this._layers = [];
		this._handlingClick = false;

	
		for (i in styles) {
		  this._addLayer(styles[i], i);
		}
	},
	onAdd: function (map) {
		var controlDiv = L.DomUtil.create('div', 'leaflet-control-layers leaflet-control-layers-expanded leaflet-control');
		L.DomEvent
			.addListener(controlDiv, 'click', L.DomEvent.stopPropagation)
			.addListener(controlDiv, 'click', L.DomEvent.preventDefault)
		.addListener(controlDiv, 'click', function () {
			drawnItems.clearLayers();
		});

		var controlUI = L.DomUtil.create('a', 'leaflet-draw-edit-remove', controlDiv);
		controlUI.title = 'Remove All Polygons';
		controlUI.href = '#';
		return controlDiv;
	}
});

// Переключение окраса по показателю


var stylesChangeble = {}
for (var group in style_groups) {
	var fields = style_groups[group].fields
	stylesChangeble[fields.style_name] = {geoserver_style:fields.geoserver_style, legend_sign:fields.legend_sign}
}

var groupedStyles = {'Заливка слоев по показателю':stylesChangeble}
var options = {
	collapsed: false,
	exclusiveGroups: ['Заливка слоев по показателю'],
	position: "topleft",
}
var stylesControl = L.control.groupedLayers(null, groupedStyles, options);

// переопределение функции клика по input для контейнера группы слоев
stylesControl._onInputClick = function () {

	var i, input, obj,
      inputs = this._form.getElementsByTagName('input'),
      inputsLen = inputs.length;

    this._handlingClick = true;

    for (i = 0; i < inputsLen; i++) {
		input = inputs[i];
		if (input.className === 'leaflet-control-layers-selector') {
			obj = this._getLayer(input.layerId)
			style = obj.layer.geoserver_style

			if (input.checked) {
				for (var layer in wmsLayers) {
					wmsLayers[layer].wmsParams.styles = style
				}
			currentTopLayer = Object.keys(workLayers._layers).filter(x => Object.keys(map._layers).includes(x))[0]
			map._layers[currentTopLayer].redraw();
			// ПОДПИСЬ к легенде
			$('.info-legend').children('div').children('b').text(obj.name);
			$('.info-legend').children('div').children('i').text(obj.layer.legend_sign);
			
			var src = `https://geoserver.bigdatamap.keenetic.pro/geoserver/wms?REQUEST=GetLegendGraphic&VERSION=1.0.0&WIDTH=30&FORMAT=image/png&LAYER=BigDataMap:${layer_name}&STYLE=${style}&legend_options=fontName:Roboto;fontAntiAliasing:true;fontSize:12;dpi:91;bgColor:0x1c2233;fontColor:0xf7f8fa`
			$('.info-legend').children('div').children('img').attr("src",src)
			
			}
      }
    }

    this._handlingClick = false;
}

if (!$.isEmptyObject(style_groups)) {
	map.addControl(stylesControl);
	stylesControl._form[0].form[0].checked = true
}


// Закрытие инфы при переключении слоя или окраса
$('input[type=radio][class=leaflet-control-layers-selector]').change(function(){
	closeInfo()
})

// Включение поиска если есть хотя бы по одному слою
for (i in layers){
	if (layers[i].fields.search_view) {
		$('.search, .search-alert').show()
	}
}

// //hover on layer
// map._layers[Object.keys(workLayers._layers).filter(x => Object.keys(map._layers).includes(x))[0]].on('mousemove', (e) => {


// 	var selectedStyle = {
// 		"color": "#fff707",
// 		"opacity": 1,
// 		'fillOpacity':0,
// 		'weight':3,
// 	};
// 	if (selectedObj) {
// 		map.removeLayer(selectedObj)
// 	}
// 	selectedObj = L.geoJSON(e.features[0], {style: selectedStyle}).addTo(map);
	
// 	renderData (attributes, data, layerPk);
// 	openBtn.style.opacity = "0";
// 	sidebar.style.width = 'auto';
// })

// function init() {
//     map = new L.Map('map');

//     // GeoServer tiles URL
//     const tilesURL = 'http://localhost:8080/geoserver/gwc/service/tms/1.0.0/adcf:epci_2018@EPSG:900913@jpeg/{z}/{x}/{y}.jpg';
//     const attr     = 'Map data © <a href="https://openstreetmap.org">OpenStreetMap</a> contributors';

//     const tilesLayer = new L.TileLayer(tilesURL, {maxZoom: 18, attribution: attr, tms: true});

//     map.setView(new L.LatLng(46.29381556233369, 2.3620605468750004), 6);
//     map.addLayer(tilesLayer);

//     // Reference to the polygon created from mousemove event
//     let hovered = null;

//     // Get tiles polygons bounding box to limit event triggering
//     const parser = new DOMParser();
//     fetch('http://localhost:8080/geoserver/wms?request=GetCapabilities').then((res) => {
//         res.text().then((xml) => {
//             const capabilities = parser.parseFromString(xml, 'text/xml');
//             const layers = capabilities.getElementsByTagName('Layer');

//             for (const layer of layers) {
//                 for (const child of layer.children) {
//                     if (child.tagName === 'Name' && child.innerHTML === 'adcf:epci_2018') {
//                         const bbox = layer.querySelectorAll('BoundingBox[CRS="EPSG:4326"]')[0];

//                         // Bouding box polygon
//                         const bboxLayer = new L.polygon([
//                             [bbox.getAttribute('minx'), bbox.getAttribute('miny')],
//                             [bbox.getAttribute('minx'), bbox.getAttribute('maxy')],
//                             [bbox.getAttribute('maxx'), bbox.getAttribute('maxy')],
//                             [bbox.getAttribute('maxx'), bbox.getAttribute('miny')],
//                         ], {color: 'red', fillOpacity: 0})
//                         // When moving over the bbox polygon, call GetFeatureInfo request to retrieve hovered polygon
//                         .on('mousemove', (e) => {
//                             // Build GetFeeatureInfo request parameters
//                             const target = map.latLngToContainerPoint(e.latlng, map.getZoom());
//                             const size   = map.getSize();

//                             const sw = map.getBounds().getSouthWest();
//                             const ne = map.getBounds().getNorthEast();

//                             const params = {
//                                 request: 'GetFeatureInfo',
//                                 query_layers: 'adcf:epci_2018',
//                                 layers: 'adcf:epci_2018',
//                                 x: Math.round(target.x),
//                                 y: Math.round(target.y),
//                                 height: size.y,
//                                 width: size.x,
//                                 info_format: 'application/json',
//                                 bbox: sw.lng + ',' + sw.lat + ',' + ne.lng + ',' + ne.lat,
//                             };

//                             // Call GetFeatureInfo request then add hovered polygon to the map
//                             fetch('http://localhost:8080/geoserver/wms' + L.Util.getParamString(params)).then((res) => {
//                                 res.json().then((json) => {
//                                     if (hovered !== null) {
//                                         map.removeLayer(hovered);
//                                     }
//                                     if (json.features.length > 0) {
//                                         hovered = L.geoJson(json).addTo(map);
//                                     }
//                                 });
//                             });

//                         })
//                         .addTo(map); 
//                     }
//                 }
//             }
//         });