"""
Phase 5: Generate CITEXT Conversion Report.

Reads manifest.json, calculates durations, generates a markdown summary
report at logs/citext-conversion-report-{timestamp}.md.

Usage:
    python 05-generate-report.py [--manifest PATH] [--report-dir PATH]
"""

import argparse
import json
from datetime import datetime
from pathlib import Path


def _parse_iso(dt_str: str) -> datetime:
    """Parse ISO 8601 datetime string."""
    # Handle both +00:00 and Z formats
    dt_str = dt_str.replace("Z", "+00:00")
    return datetime.fromisoformat(dt_str)


def _format_duration(start_str: str, end_str: str) -> str:
    """Calculate and format duration between two ISO timestamps."""
    start = _parse_iso(start_str)
    end = _parse_iso(end_str)
    delta = end - start
    total_seconds = int(delta.total_seconds())
    hours, remainder = divmod(total_seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    if hours > 0:
        return f"{hours}h {minutes}m {seconds}s"
    elif minutes > 0:
        return f"{minutes}m {seconds}s"
    else:
        return f"{seconds}s"


def _count_columns(manifest_data: dict) -> int:
    """Count total columns converted across all phases."""
    count = 0
    for phase_name, phase_data in manifest_data.get("phases", {}).items():
        completed = phase_data.get("completed", [])
        count += len(completed)
    return count


def _count_tables(manifest_data: dict) -> int:
    """Count unique tables from converted columns."""
    tables = set()
    for phase_name, phase_data in manifest_data.get("phases", {}).items():
        for entry in phase_data.get("completed", []):
            # Format: "table.column"
            parts = entry.split(".")
            if parts:
                tables.add(parts[0])
    return len(tables)


def _collect_warnings(manifest_data: dict) -> list[str]:
    """Collect warnings from all phases."""
    warnings = []
    for phase_name, phase_data in manifest_data.get("phases", {}).items():
        phase_warnings = phase_data.get("warnings", [])
        for w in phase_warnings:
            warnings.append(f"[{phase_name}] {w}")
    return warnings


def generate_report(
    manifest_path: str,
    report_dir: str = "./logs",
) -> str:
    """
    Generate a markdown conversion report from manifest data.

    Args:
        manifest_path: path to manifest.json
        report_dir: directory for report output

    Returns:
        Path to generated report file.
    """
    manifest_data = json.loads(Path(manifest_path).read_text())

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    report_path = Path(report_dir) / f"citext-conversion-report-{timestamp}.md"

    columns_converted = _count_columns(manifest_data)
    tables_converted = _count_tables(manifest_data)

    started_at = manifest_data.get("started_at", "")
    last_updated = manifest_data.get("last_updated", "")
    duration = "N/A"
    if started_at and last_updated:
        duration = _format_duration(started_at, last_updated)

    warnings = _collect_warnings(manifest_data)

    # Build report
    lines = [
        "# CITEXT Conversion Report",
        "",
        f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "|--------|-------|",
        f"| Columns Converted | {columns_converted} |",
        f"| Tables Converted | {tables_converted} |",
        f"| Duration | {duration} |",
        f"| Started At | {started_at} |",
        f"| Completed At | {last_updated} |",
        "",
        "## Phase Details",
        "",
    ]

    for phase_name, phase_data in manifest_data.get("phases", {}).items():
        status = phase_data.get("status", "unknown")
        completed_at = phase_data.get("completed_at", "N/A")
        completed_count = len(phase_data.get("completed", []))
        lines.append(f"### {phase_name}")
        lines.append(f"- **Status:** {status}")
        lines.append(f"- **Completed At:** {completed_at}")
        if completed_count:
            lines.append(f"- **Items Completed:** {completed_count}")
        lines.append("")

    # Original types section
    original_types = manifest_data.get("original_types", {})
    if original_types:
        lines.append("## Original Column Types")
        lines.append("")
        lines.append("| Column | Original Type | Length |")
        lines.append("|--------|--------------|--------|")
        for col_key, type_info in original_types.items():
            orig_type = type_info.get("type", "unknown")
            length = type_info.get("length", "N/A")
            lines.append(f"| {col_key} | {orig_type} | {length} |")
        lines.append("")

    # Warnings section
    lines.append("## Warnings")
    lines.append("")
    if warnings:
        for w in warnings:
            lines.append(f"- {w}")
    else:
        lines.append("No warnings recorded.")
    lines.append("")

    report_path.write_text("\n".join(lines))
    return str(report_path)


def run_generate_report(
    manifest_path: str,
    report_dir: str = "./logs",
) -> dict:
    """
    Orchestrate Phase 5: generate conversion report.

    Returns:
        dict with report_path.
    """
    report_path = generate_report(
        manifest_path=manifest_path,
        report_dir=report_dir,
    )

    return {
        "report_path": report_path,
    }


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Phase 5: Generate CITEXT Conversion Report"
    )
    parser.add_argument("--manifest", default="./manifest.json")
    parser.add_argument("--report-dir", default="./logs")

    args = parser.parse_args()

    result = run_generate_report(
        manifest_path=args.manifest,
        report_dir=args.report_dir,
    )
    print(f"Report generated: {result['report_path']}")


if __name__ == "__main__":
    main()
