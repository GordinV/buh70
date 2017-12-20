var tunnused =
webpackJsonp_name_([22],{

/***/ 0:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var Tunnused = __webpack_require__(220);

	// данные для хранилища
	//localStorage['docsStore'] = storeData;
	initData = JSON.parse(initData);
	userData = JSON.parse(userData);

	ReactDOM.hydrate(React.createElement(Tunnused, { id: 'tunnused', userData: userData, initData: initData }, 'Tunnused'), document.getElementById('doc'));

/***/ }),

/***/ 220:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(13);
	var Documents = __webpack_require__(162);
	var styles = __webpack_require__(221);

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Tunnused = function (_React$PureComponent) {
	    _inherits(Tunnused, _React$PureComponent);

	    function Tunnused(props) {
	        _classCallCheck(this, Tunnused);

	        return _possibleConstructorReturn(this, (Tunnused.__proto__ || Object.getPrototypeOf(Tunnused)).call(this, props));
	    }

	    _createClass(Tunnused, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(Documents, { initData: this.props.initData, userData: this.props.userData,
	                docTypeId: 'TUNNUS',
	                style: styles,
	                render: this.renderer });
	        }
	    }, {
	        key: 'renderer',
	        value: function renderer() {
	            return React.createElement(
	                'div',
	                null,
	                'Tunnused register special render'
	            );
	        }
	    }]);

	    return Tunnused;
	}(React.PureComponent);

	module.exports = Tunnused;

/***/ }),

/***/ 221:
/***/ (function(module, exports) {

	'use strict';

	module.exports = {
	    grid: {
	        mainTable: {
	            width: '100%'
	        },
	        headerTable: {
	            width: '100%'
	        },

	        gridContainer: {
	            width: '100%'
	        }

	    }
	};

/***/ })

});
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoidHVubnVzZWQuanMiLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly8vLi9mcm9udGVuZC90dW5udXNlZC5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL3R1bm51cy9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy90dW5udXMvdHVubnVzZWQtc3R5bGVzLmpzIl0sInNvdXJjZXNDb250ZW50IjpbIid1c2Ugc3RyaWN0JztcblxudmFyIFR1bm51c2VkID0gcmVxdWlyZSgnLi9kb2NzL3R1bm51cy9pbmRleC5qc3gnKTtcblxuLy8g0LTQsNC90L3Ri9C1INC00LvRjyDRhdGA0LDQvdC40LvQuNGJ0LBcbi8vbG9jYWxTdG9yYWdlWydkb2NzU3RvcmUnXSA9IHN0b3JlRGF0YTtcbmluaXREYXRhID0gSlNPTi5wYXJzZShpbml0RGF0YSk7XG51c2VyRGF0YSA9IEpTT04ucGFyc2UodXNlckRhdGEpO1xuXG5SZWFjdERPTS5oeWRyYXRlKFJlYWN0LmNyZWF0ZUVsZW1lbnQoVHVubnVzZWQsIHsgaWQ6ICd0dW5udXNlZCcsIHVzZXJEYXRhOiB1c2VyRGF0YSwgaW5pdERhdGE6IGluaXREYXRhIH0sICdUdW5udXNlZCcpLCBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgnZG9jJykpO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvdHVubnVzZWQuanNcbi8vIG1vZHVsZSBpZCA9IDBcbi8vIG1vZHVsZSBjaHVua3MgPSAyMiIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIERvY3VtZW50cyA9IHJlcXVpcmUoJy4vLi4vZG9jdW1lbnRzL2RvY3VtZW50cy5qc3gnKTtcbnZhciBzdHlsZXMgPSByZXF1aXJlKCcuL3R1bm51c2VkLXN0eWxlcycpO1xuXG4vKipcclxuICog0JrQu9Cw0YHRgSDRgNC10LDQu9C40LfRg9C10YIg0LTQvtC60YPQvNC10L3RgiDRgdC/0YDQsNCy0L7Rh9C90LjQutCwINC/0YDQuNC30L3QsNC60L7Qsi5cclxuICovXG5cbnZhciBUdW5udXNlZCA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhUdW5udXNlZCwgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gVHVubnVzZWQocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIFR1bm51c2VkKTtcblxuICAgICAgICByZXR1cm4gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKFR1bm51c2VkLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoVHVubnVzZWQpKS5jYWxsKHRoaXMsIHByb3BzKSk7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKFR1bm51c2VkLCBbe1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jdW1lbnRzLCB7IGluaXREYXRhOiB0aGlzLnByb3BzLmluaXREYXRhLCB1c2VyRGF0YTogdGhpcy5wcm9wcy51c2VyRGF0YSxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6ICdUVU5OVVMnLFxuICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMsXG4gICAgICAgICAgICAgICAgcmVuZGVyOiB0aGlzLnJlbmRlcmVyIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgJ1R1bm51c2VkIHJlZ2lzdGVyIHNwZWNpYWwgcmVuZGVyJ1xuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBUdW5udXNlZDtcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbm1vZHVsZS5leHBvcnRzID0gVHVubnVzZWQ7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL3R1bm51cy9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDIyMFxuLy8gbW9kdWxlIGNodW5rcyA9IDIyIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBncmlkOiB7XG4gICAgICAgIG1haW5UYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuICAgICAgICBoZWFkZXJUYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuXG4gICAgICAgIGdyaWRDb250YWluZXI6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfVxuXG4gICAgfVxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvdHVubnVzL3R1bm51c2VkLXN0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMjIxXG4vLyBtb2R1bGUgY2h1bmtzID0gMjIiXSwibWFwcGluZ3MiOiI7Ozs7OztBQUFBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDVEE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ2pEQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7OyIsInNvdXJjZVJvb3QiOiIifQ==