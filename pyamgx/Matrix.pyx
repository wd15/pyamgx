cdef class Matrix:
    """
    `Matrix` : Class for creating and handling AMGX Matrix objects.

    Examples
    --------

    Uploading the matrix ``[[1, 2], [3, 4]]`` using the `upload` method:

    >>> M = pyamgx.Matrix().create(rsrc)
    >>> M.upload(indptr=np.array([0, 2, 4], dtype=np.int32,
    ... indices=np.array([0, 1, 0, 1], dtype=np.int32),
    ... data=np.array([1., 2., 3., 4.], dtype=np.float64))
    """
    cdef AMGX_matrix_handle mtx
    cdef public AMGX_RC _err

    def create(self, Resources rsrc, mode='dDDI'):
        """
        M.create(Resources rsrc, mode='dDDI')
        
        Create the underlying AMGX Matrix object.

        Parameters
        ----------
        rsrc : Resources

        mode : str, optional
            String representing data modes to use.

        Returns
        -------

        self : Matrix
        """
        self._err = AMGX_matrix_create(&self.mtx, rsrc.rsrc, asMode(mode))
        return self

    def upload(self,
            np.ndarray[int, ndim=1, mode="c"] row_ptrs,
            np.ndarray[int, ndim=1, mode="c"] col_indices,
            np.ndarray[double, ndim=1, mode="c"] data,
            block_dims=[1, 1]):
        """
        M.upload(row_ptrs, col_indices, data, block_dims=[1, 1])

        Copy data from arrays describing the sparse matrix to the Matrix object.

        Parameters
        ----------
        row_ptrs : ndarray[double, ndim=1, mode="c"]
            Array of row pointers. For a description of the arrays
            `row_ptrs`, `col_indices` and `data`,
            see `here <https://en.wikipedia.org/wiki/Sparse_matrix#Compressed_sparse_row_(CSR,_CRS_or_Yale_format)>`_.
        col_indices : ndarray[double, ndim=1, mode="c"]
            Array of column indices.
        data : ndarray[double, ndim=1, mode="c"]
            Array of matrix data.
        block_dims : tuple_like, optional
            Dimensions of block in x- and y- directions. Currently
            only square blocks are supported.
        """
        cdef int block_dimx, block_dimy

        block_dimx = block_dims[0]
        block_dimy = block_dims[1]

        n = len(row_ptrs) - 1
        nnz = len(data)

        self._err = AMGX_matrix_upload_all(self.mtx,
                n, nnz, block_dimx, block_dimy,
                &row_ptrs[0], &col_indices[0],
                &data[0], NULL)

    def upload_CSR(self, csr):
        """
        M.upload(csr)

        Copy data from a `scipy.sparse.csr_matrix` to the Matrix object.

        Parameters
        ----------
        csr : scipy.sparse.csr_matrix
        """
        n = csr.shape[0]
        nnz = csr.nnz
        row_ptrs = csr.indptr
        col_indices = csr.indices
        data = csr.data
        self.upload(n, nnz, row_ptrs, col_indices, data)

    def get_size(self):
        cdef int n, bx, by
        self._err = AMGX_matrix_get_size(self.mtx,
            &n, &bx, &by)
        return n, [bx, by]
    
    def destroy(self):
        """
        M.destroy()

        Destroy the underlying AMGX Matrix object.
        """
        self._err = AMGX_matrix_destroy(self.mtx)