# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Unit tests for document formatting templates."""

from unittest.mock import MagicMock

from app.templates import format_docs


def test_format_docs_single_document() -> None:
    """Test formatting a single document."""
    # Arrange
    mock_doc = MagicMock()
    mock_doc.page_content = "This is test content"

    # Act
    result = format_docs.format(docs=[mock_doc])

    # Assert
    assert "## Context provided:" in result
    assert "<Document 0>" in result
    assert "This is test content" in result
    assert "</Document 0>" in result


def test_format_docs_multiple_documents() -> None:
    """Test formatting multiple documents with proper indexing."""
    # Arrange
    mock_doc1 = MagicMock()
    mock_doc1.page_content = "First document content"
    mock_doc2 = MagicMock()
    mock_doc2.page_content = "Second document content"
    mock_doc3 = MagicMock()
    mock_doc3.page_content = "Third document content"

    # Act
    result = format_docs.format(docs=[mock_doc1, mock_doc2, mock_doc3])

    # Assert
    assert "## Context provided:" in result
    assert "<Document 0>" in result
    assert "First document content" in result
    assert "<Document 1>" in result
    assert "Second document content" in result
    assert "<Document 2>" in result
    assert "Third document content" in result


def test_format_docs_empty_list() -> None:
    """Test formatting with empty document list."""
    # Act
    result = format_docs.format(docs=[])

    # Assert
    assert "## Context provided:" in result
    # Should not contain any Document tags
    assert "<Document" not in result


def test_format_docs_handles_special_characters() -> None:
    """Test formatting documents with special characters."""
    # Arrange
    mock_doc = MagicMock()
    mock_doc.page_content = 'Content with <special> & "characters"'

    # Act
    result = format_docs.format(docs=[mock_doc])

    # Assert - Jinja2 safe filter should preserve content
    assert 'Content with <special> & "characters"' in result


def test_format_docs_preserves_whitespace() -> None:
    """Test that formatting preserves whitespace and line breaks."""
    # Arrange
    mock_doc = MagicMock()
    mock_doc.page_content = "Line 1\nLine 2\n  Indented line"

    # Act
    result = format_docs.format(docs=[mock_doc])

    # Assert
    assert "Line 1\nLine 2\n  Indented line" in result
