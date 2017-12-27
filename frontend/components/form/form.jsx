
const PropTypes = require('prop-types');

const React = require('react'),
    PageLabel = require('../page-label/page-label.jsx'),
    styles = require('./form-styles');

class Form extends React.PureComponent {
    constructor(props) {
        super(props);
        this.handlePageClick = this.handlePageClick.bind(this);

    }

    /**
     * Обработчик клика вкладки
     * @param page
     */
    handlePageClick(page) {

        if (this.props.handlePageClick) {
            this.props.handlePageClick(page);
        }
    }

    render() {
        let pages = this.props.pages;
        return (
            <div>
                {pages.length ? pages.map((page, idx) => {
                        return <PageLabel
                            key={idx}
                            active={idx == 0 ? true: false }
                            handlePageClick={this.handlePageClick}
                            page={page}
                            disabled = {this.props.disabled}
                            ref={'page-' + idx}/>
                    }
                ): null}
                <div style={styles.page}>
                        {this.props.children}
                </div>
            </div>
        );
    }
}

Form.propTypes = {
    pages: PropTypes.array.isRequired,
    handlePageClick: PropTypes.func,
    disabled: PropTypes.bool
};


Form.defaultProps = {
    disabled: false.valueOf(),
    pages: []
};

module.exports = Form;