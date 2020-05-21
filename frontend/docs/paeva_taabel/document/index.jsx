'use strict';

const PropTypes = require('prop-types');
const React = require('react');


const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    ButtonEdit = require('../../../components/button-register/button-register-edit/button-register-edit.jsx'),
    BtnArvesta = require('../../../components/button-register/button-task/index.jsx'),
    Select = require('../../../components/select/select.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),

    styles = require('./styles');
const LIBRARIES = [
    {
        id: 'lapse_grupp',
        filter: ``
    }
];

const DocContext = require('../../../doc-context');

class PaevaTaabel extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            module: 'lapsed',
            loadedData: false,
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            grupp_id: null,
            kpv: null,
            isRebuild: false,
            isInit: true,
            kogus: 0
        };

        this.renderer = this.renderer.bind(this);
        this.handlePageClick = this.handlePageClick.bind(this);
        this.onClickHandler = this.onClickHandler.bind(this);
        this.handleGridRow = this.handleGridRow.bind(this);
        this.prepaireInitData = this.prepaireInitData.bind(this);
        this.handleGridCellClick = this.handleGridCellClick.bind(this);
        this.btnEditGruppClick = this.btnEditGruppClick.bind(this);
        this.handleHeaderClick = this.handleHeaderClick.bind(this);
        this.checkData = this.checkData.bind(this);

        this.pages = [
            {pageName: 'Päeva taabel', docTypeId: 'PAEVA_TAABEL'}
        ];

        this.subtotals = ['osalemine'];

    }

    componentDidMount() {
        if (!this.state.lapsId && DocContext['laps']) {
            //есть значение ид ребенка
            this.setState({lapsId: DocContext['laps']});
        }
    }


    componentDidUpdate(prevProps, prevState) {
        // обновим справочники ребенка
        if (this.state.lapsId !== prevState.lapsId) {
            const doc = this.refs['document'];
            doc.createLibs();
        }

    }

    render() {
        let filter = this.state.lapsId ? `where lapsid = ${this.state.lapsId}` : '';
        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='PAEVA_TAABEL'
                                 module={this.state.module}
                                 initData={this.props.initData}
                                 libs={LIBRARIES}
                                 renderer={this.renderer}
                                 handleGridBtnClick={this.handleGridBtnClick}
                                 history={this.props.history}
                                 isDisableSave={!this.state.docId}
                                 isGridDataSave={true}
                                 trigger={this.checkData}

        />
    }

    /**
     * поправит данные для грида
     */
    prepaireInitData(self) {
        if (self.docData.gridData && self.docData.gridData.length && self.docData.noms && self.docData.noms.length) {

            // add column nomid to grid
            self.docData.noms.forEach(nom => {
                let column = self.docData.gridConfig.find(row => row.id == String(nom.nom_id));
                // отсекаем услуги, которые не определены как дневные и те, что уже обрабтаны
                if (nom.teenus && !column) {
                    self.docData.gridConfig.push({
                        id: String(nom.nom_id),
                        name: nom.teenus,
                        width: `50px`,
                        type: "boolean"
                    });
                }
            });

            // кол-во услуг
            self.docData.gridData = self.docData.gridData.map(row => {
                row.noms.forEach(nom => {
                    if (row[String(nom.nom_id)]) {
                        // juba olemas
                    } else {
                        row[String(nom.nom_id)] = !!nom.kogus;
                    }
                });
                return row;
            });
            this.setState({isInit: false});

        }

    }


    /**
     *Вернет кастомные компоненты документа
     */

    renderer(self) {
        let isEditMode = self.state.edited;
        if (self.docData && self.docData.gridData && self.docData.gridData.length && (this.state.isInit || !isEditMode)) {
            // преобразовываем данные
            this.prepaireInitData(self);

            // найдем числовые поля и поставим их в массив для передачи в грид для суммирования итогов
            const reg = /^\d+$/; // только номера

            self.docData.gridConfig.forEach(row => {
                if (reg.test(row.id)) {
                    if (!this.subtotals.some(item => item == row.id)) {
                        this.subtotals.push(row.id);
                    }

                }
            });

        }
        this.setState({grupp_id: self.docData.grupp_id, kpv: self.docData.kpv});
        const gridStyle = {...styles.grid.headerTable, ...styles.grid};

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputDate title='Kuupäev '
                                   name='kpv'
                                   value={self.docData.kpv}
                                   ref='input-kpv'
                                   readOnly={!isEditMode}
                                   disabled={!!self.docData.id}
                                   onChange={self.handleInputChange}/>
                    </div>
                    <div style={styles.docColumn}>
                        <InputText title='Staatus'
                                   name='status'
                                   value={self.docData.status || ''}
                                   ref='input-status'
                                   readOnly={true}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>

                        <Select title="Üksus:"
                                name='grupp_id'
                                libs="lapse_grupp"
                                data={self.libs['lapse_grupp']}
                                value={self.docData.grupp_id || 0}
                                defaultValue={self.docData.yksys || ''}
                                ref="select-lapse_grupp"
                                collId={'id'}
                                btnDelete={isEditMode}
                                onChange={self.handleInputChange}
                                disabled={!!self.docData.id}
                                readOnly={!isEditMode}
                        />
                    </div>
                    {!self.docData.id && self.docData.grupp_id ? (
                        <div style={styles.docColumn}>
                            <BtnArvesta
                                value={'Arvesta taabel ?'}
                                onClick={this.onClickHandler}
                                showDate={false}
                                ref={`btn-arvesta`}
                                key={`key-arvesta`}
                            />

                        </div>) : null
                    }
                    <div style={styles.docColumn}>
                        <ButtonEdit
                            ref='btnEdit'
                            value={'Muuda'}
                            onClick={this.btnEditGruppClick}
                            show={!isEditMode}
                            style={styles.btnEdit}
                            disabled={false}
                        />
                    </div>

                </div>
                <div style={styles.docRow}>
                    <DataGrid source='details'
                              gridData={self.docData.gridData}
                              gridColumns={self.docData.gridConfig}
                              showToolBar={false}
                              handleGridRow={this.handleGridRow}
                              onHeaderClick={this.handleHeaderClick}
                              onClick={self.handleGridCellClick}
                              readOnly={!isEditMode}
                              style={gridStyle}
                              isForUpdate={isEditMode}
                              subtotals={this.subtotals}
                              ref="data-grid"/>
                </div>
                {self.docData.id ?
                    <div style={styles.docRow}>
                        <TextArea title="Märkused"
                                  name='muud'
                                  ref="textarea-muud"
                                  onChange={self.handleInputChange}
                                  value={self.docData.muud || ''}
                                  readOnly={!isEditMode}/>
                    </div> : null}
            </div>
        );
    }

    handlePageClick(pageDocTypeId) {
        this.props.history.push(`/lapsed/${pageDocTypeId}`)
    }

    onClickHandler(name, value) {
        const Doc = this.refs['document'];
        let api = `/newApi/task/arvestaPaevaTaabel`;

        Doc.fetchData('Post', api, {seisuga: this.state.kpv, docId: this.state.grupp_id}).then((response) => {
            if (response.data && response.data.error_code) {
                Doc.setState({
                    warning: response.data.error_message,
                    warningType: 'error'
                }, () => {
                    this.forceUpdate();
                });

            } else {

                let docId = response.data && response.data.result ? response.data.result : null;
                if (docId) {
                    // reload / redirect
                    const current = `/lapsed/paeva_taabel/${docId}`;
                    this.props.history.replace(`/reload`);
                    setTimeout(() => {
                        this.props.history.replace(current);
                    });
                }

            }
        })
    }

    /**
     * будет вызвана триггером при ихменении. Проврит поля посещаемости и если нет, то проставит нет всем услушам
     * @param self
     */
    checkData(self, idx, columnId, value) {
        if (columnId && columnId == 'osalemine') {
            if (!self.docData.gridData[idx].osalemine) {
                // обнулить значения всех услуг
                for (let [key, value] of Object.entries(self.docData.gridData[idx])) {
                    if (!isNaN(key) && !!value) {
                        // посещения нет, а значение положительное. меняем
                        self.docData.gridData[idx][key] = !value;
                    }
                }
            }
        }

    }

    handleGridRow(gridEvent) {
        this.setState({gridRowEdit: true, gridRowEvent: gridEvent});
    }

    /**
     * обработчик события клика по колонке
     * @param header
     */
    handleHeaderClick(header) {
        let isEditeMode = this.refs['document'].state.edited;
        if (!isEditeMode) {
            console.log('not in edit mode');
            return;
        }

        let column = header[0].column;
        // проверим на колонку со значением кол-ва услуг
        if (isNaN(Number(column))) {
            console.log('vale verg, ignoreerime');
            return;
        }

        // надо пройти циклом и поменять значение в указанном поле
        const data = this.refs['document'].docData;
        if (data && data.gridData && data.gridData.length) {
            data.gridData.forEach(row => {
                if (row[column] !== null && row[column] !== undefined) {
                    row[column] = !row[column];
                }
            });
        }
    }

    handleGridCellClick(action, docId, idx, columnId) {
        gridData[idx][columnId] = !gridData[idx][columnId];
    }

    /**
     *     /обработчик события клиска на кнопке редактирования группы
     */
    btnEditGruppClick() {
        let docGruppId = this.refs['document'].docData.grupp_id;

        // осуществит переход на карточку
        this.props.history.push(`/${this.state.module}/lapse_grupp/${docGruppId}`);

    }


}

PaevaTaabel.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

PaevaTaabel.defaultProps = {
    params: {docId: 0},
    initData: {},
    userData: {}
};


module.exports = (PaevaTaabel);