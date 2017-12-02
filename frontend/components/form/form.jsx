
const PropTypes = require('prop-types');

const React = require('react'),
    flux = require('fluxify'),
    PageLabel = require('../page-label/page-label.jsx'),
    styles = require('./form-styles');

class Form extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            pages: this.props.pages
        };
        this.handlePageClick = this.handlePageClick.bind(this);

    }

    handlePageClick(page) {

        if (this.props.handlePageClick) {
            this.props.handlePageClick(page);
        }
    }

    render() {
        let pages = this.state.pages;

        return (
            <div>
                {pages.map((page, idx) => {
                        return <PageLabel
                            key={idx}
                            active={idx == 0 ? true: false }
                            handlePageClick={this.handlePageClick}
                            page={page}
                            disabled = {this.props.disabled}
                            ref={'page-' + idx}/>
                    }
                )}
                <div style={styles.page}>
                        {this.props.children}
                </div>
            </div>
        )
    }
}
;


Form.propTypes = {
    pages: PropTypes.array.isRequired,
    handlePageClick: PropTypes.func,
    disabled: PropTypes.bool
}


Form.defaultProps = {
    disabled: false.valueOf(),
    pages: []
}

module.exports = Form;